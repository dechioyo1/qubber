import os
import random
import logging
from .store import OmemoStore
from .pep import OmemoPEP
from .x3dh import X3DHAgreement
from .double_ratchet import DoubleRatchetSession
from .crypto import (
    generate_identity_keypair,
    generate_x25519_keypair,
    split_identity_key,
    strip_type_byte,
    sign_ed25519,
    format_fingerprint,
    b64_encode,
    b64_decode,
    aes_gcm_encrypt,
    aes_gcm_decrypt
)

class OmemoManager:
    def __init__(self, db_path=None, data_dir=None):
        if not db_path and data_dir:
            os.makedirs(data_dir, exist_ok=True)
            db_path = os.path.join(data_dir, "omemo.db")
        self.store = OmemoStore(db_path)
        self.sessions = {} # (peer_jid, device_id) -> DoubleRatchetSession
        self._load_or_generate_identity()

    def _load_or_generate_identity(self):
        row = self.store.load_identity()
        if row and len(row[1]) >= 64 and len(row[2]) >= 64:
            self.device_id, self.pub_key_bytes, self.priv_key_bytes, self.fingerprint = row
        else:
            self.device_id = random.randint(10000000, 99999999)
            self.priv_key_bytes, self.pub_key_bytes = generate_identity_keypair()
            self.fingerprint = format_fingerprint(self.pub_key_bytes)
            self.store.save_identity(self.device_id, self.pub_key_bytes, self.priv_key_bytes, self.fingerprint)

            # Generate Signed Prekey (X25519) and sign with Ed25519 identity portion
            ik_ed_priv, _ = split_identity_key(self.priv_key_bytes)
            spk_priv, spk_pub = generate_x25519_keypair()
            spk_sig = sign_ed25519(ik_ed_priv, spk_pub)
            self.store.save_signed_prekey(1, spk_pub, spk_priv, spk_sig)

            # Generate 10 One-Time Prekeys
            prekeys = []
            for i in range(1, 11):
                pk_priv, pk_pub = generate_x25519_keypair()
                prekeys.append((i, pk_pub, pk_priv))
            self.store.save_prekeys(prekeys)

            logging.info(f"Generated new OMEMO Identity Keys. Device ID: {self.device_id}, Fingerprint: {self.fingerprint}")

        # Ensure signed prekey attributes exist
        spk_row = self.store.load_signed_prekey(1)
        ik_ed_priv, _ = split_identity_key(self.priv_key_bytes)
        if spk_row:
            self.spk_pub_bytes, self.spk_priv_bytes, _ = spk_row
            spk_clean = strip_type_byte(self.spk_pub_bytes)
            self.spk_sig_bytes = sign_ed25519(ik_ed_priv, b"\x05" + spk_clean)
            self.store.save_signed_prekey(1, self.spk_pub_bytes, self.spk_priv_bytes, self.spk_sig_bytes)
        else:
            spk_priv, spk_pub = generate_x25519_keypair()
            spk_clean = strip_type_byte(spk_pub)
            spk_sig = sign_ed25519(ik_ed_priv, b"\x05" + spk_clean)
            self.store.save_signed_prekey(1, spk_pub, spk_priv, spk_sig)
            self.spk_pub_bytes, self.spk_priv_bytes, self.spk_sig_bytes = spk_pub, spk_priv, spk_sig

    def get_device_id(self) -> int:
        return self.device_id

    def get_fingerprint(self) -> str:
        return self.fingerprint

    def get_db_path(self) -> str:
        return self.store.db_path

    def regenerate_keys(self) -> bool:
        try:
            self.store.clear_identity_and_keys()
            self._load_or_generate_identity()
            self.sessions.clear()
            logging.info(f"Regenerated OMEMO keys. New Device ID: {self.device_id}, Fingerprint: {self.fingerprint}")
            return True
        except Exception as e:
            logging.error(f"Failed to regenerate OMEMO keys: {e}")
            return False

    def clear_all_keys(self) -> bool:
        return self.regenerate_keys()

    def get_bundle_data(self) -> dict:
        ik_b64 = b64_encode(b"\x05" + self.pub_key_bytes)
        spk_b64 = b64_encode(b"\x05" + strip_type_byte(self.spk_pub_bytes))

        prekey_rows = self.store.load_prekeys()
        prekeys_list = [{'id': r[0], 'public_key': b64_encode(b"\x05" + strip_type_byte(r[1]))} for r in prekey_rows]

        return {
            'identity_key': ik_b64,
            'signed_prekey_id': 1,
            'signed_prekey': spk_b64,
            'signed_prekey_sig': b64_encode(self.spk_sig_bytes),
            'prekeys': prekeys_list
        }

    def store_peer_bundle(self, peer_jid: str, device_id: int, identity_key_b64: str, signed_prekey_b64: str, signed_prekey_sig_b64: str = None):
        self.store.store_bundle(peer_jid, device_id, identity_key_b64, signed_prekey_b64, signed_prekey_sig_b64)

    def is_encryption_enabled(self, peer_jid: str) -> bool:
        return self.store.is_chat_encryption_enabled(peer_jid)

    def set_encryption_enabled(self, peer_jid: str, enabled: bool):
        self.store.set_chat_encryption(peer_jid, enabled)

    def get_peer_fingerprints(self, peer_jid: str) -> list[dict]:
        bundles = self.store.load_peer_bundles(peer_jid)
        res = []
        for dev_id, ik_b64, spk_b64, spk_sig_b64 in bundles:
            try:
                ik_bytes = b64_decode(ik_b64)
                res.append({
                    'device_id': dev_id,
                    'fingerprint': format_fingerprint(ik_bytes)
                })
            except Exception:
                pass
        return res

    def get_or_create_session(self, peer_jid: str, device_id: int, ik_bytes: bytes, spk_bytes: bytes, spk_sig_bytes: bytes) -> tuple[DoubleRatchetSession, dict]:
        bare_jid = peer_jid.split('/')[0] if peer_jid else ""
        key = (bare_jid, device_id)
        if key in self.sessions:
            return self.sessions[key], None

        # Check DB
        state_dict = self.store.load_session(bare_jid, device_id)
        if state_dict:
            session = DoubleRatchetSession.import_state(state_dict)
            self.sessions[key] = session
            return session, None

        # Perform X3DH key agreement
        shared_master, alice_ek_pub, x3dh_header = X3DHAgreement.initiate(
            alice_ik_priv=self.priv_key_bytes,
            alice_ik_pub=self.pub_key_bytes,
            bob_ik_pub=ik_bytes,
            bob_spk_pub=spk_bytes,
            bob_spk_sig=spk_sig_bytes
        )

        spk_clean = strip_type_byte(spk_bytes)[:32]
        session = DoubleRatchetSession(shared_master, is_initiator=True, remote_dh_pub=spk_clean)
        self.store.save_session(bare_jid, device_id, session.export_state())
        self.sessions[key] = session
        return session, x3dh_header

    def encrypt_payload(self, peer_jid: str, plaintext_body: str, target_device_ids: list[int] = None) -> tuple[dict, str]:
        """
        Encrypt payload for peer_jid devices.
        Returns:
            - omemo_stanza_data (dict)
            - fallback_text (str)
        """
        try:
            bare_jid = peer_jid.split('/')[0] if peer_jid else ""
            payload_bytes = plaintext_body.encode('utf-8')
            
            # Generate random symmetric key for message payload (16 bytes)
            payload_key = os.urandom(16)
            iv, ciphertext = aes_gcm_encrypt(payload_key, payload_bytes)
            
            iv_b64 = b64_encode(iv)
            ct_b64 = b64_encode(ciphertext)
            
            keys_map = {}
            all_bundles = self.store.load_peer_bundles(bare_jid)
            if target_device_ids is not None:
                target_ids_set = {int(x) for x in target_device_ids}
                bundles = [b for b in all_bundles if b[0] in target_ids_set]
            else:
                bundles = all_bundles
            logging.info(f"[OMEMO Manager] Encrypting message for {bare_jid} across {len(bundles)} cached target device(s)...")
            
            if len(bundles) == 0:
                logging.warning(f"[OMEMO Manager] No cached peer OMEMO key bundles for {bare_jid}. Falling back to standard message.")
                return None, plaintext_body
            
            for dev_id, ik_b64, spk_b64, spk_sig_b64 in bundles:
                try:
                    ik_bytes = b64_decode(ik_b64)
                    spk_bytes = b64_decode(spk_b64)
                    spk_sig = b64_decode(spk_sig_b64) if spk_sig_b64 else None

                    session, x3dh_header = self.get_or_create_session(bare_jid, dev_id, ik_bytes, spk_bytes, spk_sig)
                    header, key_iv, enc_key = session.ratchet_encrypt(payload_key)
                    self.store.save_session(bare_jid, dev_id, session.export_state())
                    
                    keys_map[dev_id] = {
                        'key': b64_encode(enc_key),
                        'iv': b64_encode(key_iv),
                        'dh': header['dh'],
                        'n': header['n'],
                        'prekey': True if x3dh_header else False,
                        'ek': x3dh_header['ek'] if x3dh_header else None,
                        'ik': x3dh_header['ik'] if x3dh_header else None
                    }
                    logging.info(f"[OMEMO Manager] Encrypted payload key for device {dev_id} (n={header['n']})")
                except Exception as ex:
                    logging.error(f"Could not ratchet encrypt for {bare_jid}:{dev_id}: {ex}", exc_info=True)

            # Store key for self device as well
            keys_map[self.device_id] = {
                'key': b64_encode(payload_key),
                'iv': None,
                'dh': None,
                'n': 0,
                'prekey': False
            }

            omemo_data = {
                'sid': self.device_id,
                'iv': iv_b64,
                'payload': ct_b64,
                'keys': keys_map
            }
            fallback = "[This message is encrypted with OMEMO End-to-End Encryption]"
            logging.info(f"[OMEMO Manager] Successfully prepared encrypted OMEMO stanza (Sender Device SID: {self.device_id}, Target Devices: {list(keys_map.keys())})")
            return omemo_data, fallback
        except Exception as e:
            logging.error(f"OMEMO Encryption error: {e}", exc_info=True)
            return None, plaintext_body

    def decrypt_payload(self, peer_jid: str, omemo_data: dict) -> str:
        """
        Decrypt incoming OMEMO payload dict.
        """
        try:
            bare_jid = peer_jid.split('/')[0] if peer_jid else ""
            iv_b64 = omemo_data.get('iv')
            ct_b64 = omemo_data.get('payload')
            keys_map = omemo_data.get('keys', {})
            sender_sid = omemo_data.get('sid')
            
            logging.info(f"[OMEMO Manager] Decrypting incoming OMEMO payload from sender {peer_jid} (Sender SID: {sender_sid}, Target Devices: {list(keys_map.keys())})...")

            if not iv_b64 or not ct_b64:
                logging.error("[OMEMO Manager] Missing IV or Ciphertext in OMEMO payload!")
                return None

            iv = b64_decode(iv_b64)
            ciphertext = b64_decode(ct_b64)
            
            key_info = keys_map.get(self.device_id) or keys_map.get(str(self.device_id))
            if not key_info and len(keys_map) > 0:
                key_info = list(keys_map.values())[0]
                
            if not key_info:
                logging.error(f"[OMEMO Manager] Device ID {self.device_id} key not found in incoming payload keys!")
                return None

            if isinstance(key_info, str):
                key_info = {'key': key_info}

            enc_key_b64 = key_info.get('key')
            key_iv_b64 = key_info.get('iv')
            dh_b64 = key_info.get('dh')
            msg_n = key_info.get('n', 0)
            is_prekey = key_info.get('prekey', False)
            ek_b64 = key_info.get('ek')
            ik_b64 = key_info.get('ik')

            if not enc_key_b64:
                logging.error("[OMEMO Manager] Missing enc_key_b64 in payload key info!")
                return None

            # Get or create ratchet session for sender_sid
            session_key = (bare_jid, int(sender_sid) if sender_sid else 0)
            session = self.sessions.get(session_key)

            if not session and sender_sid:
                state_dict = self.store.load_session(bare_jid, int(sender_sid))
                if state_dict:
                    session = DoubleRatchetSession.import_state(state_dict)
                    self.sessions[session_key] = session

            if not session:
                # Initialize session via X3DH respond
                if is_prekey and ek_b64 and ik_b64:
                    alice_ik_pub = b64_decode(ik_b64)
                    alice_ek_pub = b64_decode(ek_b64)
                    master_sk = X3DHAgreement.respond(
                        bob_ik_priv=self.priv_key_bytes,
                        bob_spk_priv=self.spk_priv_bytes,
                        alice_ik_pub=alice_ik_pub,
                        alice_ek_pub=alice_ek_pub
                    )
                    remote_dh = b64_decode(dh_b64) if dh_b64 else alice_ek_pub
                    session = DoubleRatchetSession(
                        master_sk,
                        is_initiator=False,
                        remote_dh_pub=remote_dh,
                        local_dh_priv=self.spk_priv_bytes,
                        local_dh_pub=self.spk_pub_bytes
                    )
                    if sender_sid:
                        self.store.save_session(bare_jid, int(sender_sid), session.export_state())
                        self.sessions[session_key] = session
                else:
                    # Fallback: check stored peer bundle
                    peer_bundle = self.store.load_peer_bundle(bare_jid, int(sender_sid)) if sender_sid else None
                    if peer_bundle:
                        ik_bytes = b64_decode(peer_bundle[1])
                        spk_bytes = b64_decode(peer_bundle[2])
                        spk_sig = b64_decode(peer_bundle[3]) if peer_bundle[3] else None
                        session, _ = self.get_or_create_session(bare_jid, int(sender_sid), ik_bytes, spk_bytes, spk_sig)

            if not session or not key_iv_b64:
                # Plaintext fallback key stored for self device
                payload_key = b64_decode(enc_key_b64)
            else:
                enc_key_bytes = b64_decode(enc_key_b64)
                key_iv_bytes = b64_decode(key_iv_b64)
                header = {'dh': dh_b64, 'n': msg_n}
                payload_key = session.ratchet_decrypt(header, iv=key_iv_bytes, ciphertext=enc_key_bytes)
                if sender_sid:
                    self.store.save_session(bare_jid, int(sender_sid), session.export_state())

            plaintext_bytes = aes_gcm_decrypt(payload_key, iv, ciphertext)
            decrypted_str = plaintext_bytes.decode('utf-8')
            logging.info(f"[OMEMO Manager] Successfully decrypted OMEMO message ({len(plaintext_bytes)} bytes)")
            return decrypted_str
        except Exception as e:
            logging.error(f"OMEMO Decryption error: {e}", exc_info=True)
            return None
