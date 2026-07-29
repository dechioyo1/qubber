import hmac
import hashlib
import logging
from .crypto import (
    generate_x25519_keypair,
    dh_exchange,
    hkdf_derive,
    aes_gcm_encrypt,
    aes_gcm_decrypt,
    b64_encode,
    b64_decode
)

class DoubleRatchetSession:
    """
    Implements the Double Ratchet Algorithm (Signal / XEP-0384).
    Manages Root Key (RK), Chain Keys (CKs, CKr), DH ratchet step, and symmetric message key derivation.
    """
    def __init__(
        self,
        shared_key: bytes,
        is_initiator: bool,
        remote_dh_pub: bytes = None,
        local_dh_priv: bytes = None,
        local_dh_pub: bytes = None
    ):
        self.root_key = shared_key
        self.sending_chain_key = None
        self.receiving_chain_key = None
        
        if local_dh_priv and local_dh_pub:
            self.dh_local_priv = local_dh_priv
            self.dh_local_pub = local_dh_pub
        else:
            self.dh_local_priv, self.dh_local_pub = generate_x25519_keypair()

        self.dh_remote_pub = remote_dh_pub
        self.send_count = 0
        self.recv_count = 0
        self.skipped_message_keys = {} # (remote_dh_pub, n) -> message_key

        logging.info(f"[OMEMO Ratchet] Initializing Double Ratchet Session (initiator={is_initiator}, remote_dh={b64_encode(remote_dh_pub)[:12] if remote_dh_pub else 'None'}...)")

        if is_initiator and remote_dh_pub:
            dh_out = dh_exchange(self.dh_local_priv, self.dh_remote_pub)
            self.root_key, self.sending_chain_key = self._kdf_rk(dh_out)
            logging.info(f"[OMEMO Ratchet] Initialized Sending Chain Key for initiator (DH local: {b64_encode(self.dh_local_pub)[:12]}...)")
        elif not is_initiator and remote_dh_pub:
            dh_out = dh_exchange(self.dh_local_priv, self.dh_remote_pub)
            self.root_key, self.receiving_chain_key = self._kdf_rk(dh_out)
            logging.info(f"[OMEMO Ratchet] Initialized Receiving Chain Key for responder (DH local: {b64_encode(self.dh_local_pub)[:12]}...)")

    def _kdf_rk(self, dh_out: bytes) -> tuple[bytes, bytes]:
        derived = hkdf_derive(dh_out, salt=self.root_key, info=b"OMEMO Double Ratchet RK", length=64)
        return derived[:32], derived[32:]

    def _kdf_ck(self, chain_key: bytes) -> tuple[bytes, bytes]:
        msg_key = hmac.new(chain_key, b"\x01", hashlib.sha256).digest()[:16]
        next_chain_key = hmac.new(chain_key, b"\x02", hashlib.sha256).digest()
        return next_chain_key, msg_key

    def ratchet_encrypt(self, plaintext: bytes) -> tuple[dict, bytes, bytes]:
        if not self.sending_chain_key:
            if self.dh_remote_pub:
                self.dh_local_priv, self.dh_local_pub = generate_x25519_keypair()
                dh_out = dh_exchange(self.dh_local_priv, self.dh_remote_pub)
                self.root_key, self.sending_chain_key = self._kdf_rk(dh_out)
                self.send_count = 0
            else:
                raise ValueError("Sending chain key is not initialized!")

        self.sending_chain_key, msg_key = self._kdf_ck(self.sending_chain_key)
        iv, ciphertext = aes_gcm_encrypt(msg_key, plaintext)
        
        header = {
            "dh": b64_encode(self.dh_local_pub),
            "n": self.send_count
        }
        logging.info(f"[OMEMO Ratchet] Ratchet Encrypt -> Message Index #{self.send_count} (DH local pub: {b64_encode(self.dh_local_pub)[:12]}...)")
        self.send_count += 1
        return header, iv, ciphertext

    def ratchet_decrypt(self, header: dict, iv: bytes, ciphertext: bytes) -> bytes:
        remote_dh_bytes = b64_decode(header["dh"]) if isinstance(header.get("dh"), str) else header.get("dh")
        msg_num = int(header.get("n", 0))

        logging.info(f"[OMEMO Ratchet] Ratchet Decrypt <- Message Index #{msg_num} (DH remote pub: {b64_encode(remote_dh_bytes)[:12]}...)")

        if (remote_dh_bytes, msg_num) in self.skipped_message_keys:
            msg_key = self.skipped_message_keys.pop((remote_dh_bytes, msg_num))
            return aes_gcm_decrypt(msg_key, iv, ciphertext)

        if remote_dh_bytes and remote_dh_bytes != self.dh_remote_pub:
            self._skip_message_keys(msg_num)
            self._dh_ratchet(remote_dh_bytes)

        self._skip_message_keys(msg_num)
        if not self.receiving_chain_key:
            if self.dh_remote_pub:
                dh_out = dh_exchange(self.dh_local_priv, self.dh_remote_pub)
                self.root_key, self.receiving_chain_key = self._kdf_rk(dh_out)
                self.recv_count = 0
            else:
                raise ValueError("Receiving chain key is not initialized!")

        self.receiving_chain_key, msg_key = self._kdf_ck(self.receiving_chain_key)
        self.recv_count += 1
        return aes_gcm_decrypt(msg_key, iv, ciphertext)

    def _dh_ratchet(self, remote_dh_pub: bytes):
        logging.info(f"[OMEMO Ratchet] Executing DH Ratchet Step for remote DH pub: {b64_encode(remote_dh_pub)[:12]}...")
        self.dh_remote_pub = remote_dh_pub
        self.recv_count = 0

        # Receive DH Step
        dh_out = dh_exchange(self.dh_local_priv, self.dh_remote_pub)
        self.root_key, self.receiving_chain_key = self._kdf_rk(dh_out)

        # Send DH Step (generate new local keypair)
        self.dh_local_priv, self.dh_local_pub = generate_x25519_keypair()
        dh_out2 = dh_exchange(self.dh_local_priv, self.dh_remote_pub)
        self.root_key, self.sending_chain_key = self._kdf_rk(dh_out2)
        self.send_count = 0
        logging.info(f"[OMEMO Ratchet] Advanced Root Key & Generated New Local DH Keypair: {b64_encode(self.dh_local_pub)[:12]}...")

    def _skip_message_keys(self, until_n: int):
        if not self.receiving_chain_key:
            return
        while self.recv_count < until_n:
            self.receiving_chain_key, msg_key = self._kdf_ck(self.receiving_chain_key)
            self.skipped_message_keys[(self.dh_remote_pub, self.recv_count)] = msg_key
            logging.info(f"[OMEMO Ratchet] Skipped message key for index #{self.recv_count}")
            self.recv_count += 1

    def export_state(self) -> dict:
        return {
            "root_key": b64_encode(self.root_key),
            "sending_chain_key": b64_encode(self.sending_chain_key) if self.sending_chain_key else None,
            "receiving_chain_key": b64_encode(self.receiving_chain_key) if self.receiving_chain_key else None,
            "dh_local_priv": b64_encode(self.dh_local_priv),
            "dh_local_pub": b64_encode(self.dh_local_pub),
            "dh_remote_pub": b64_encode(self.dh_remote_pub) if self.dh_remote_pub else None,
            "send_count": self.send_count,
            "recv_count": self.recv_count
        }

    @classmethod
    def import_state(cls, state: dict):
        obj = cls.__new__(cls)
        obj.root_key = b64_decode(state["root_key"])
        obj.sending_chain_key = b64_decode(state["sending_chain_key"]) if state.get("sending_chain_key") else None
        obj.receiving_chain_key = b64_decode(state["receiving_chain_key"]) if state.get("receiving_chain_key") else None
        obj.dh_local_priv = b64_decode(state["dh_local_priv"])
        obj.dh_local_pub = b64_decode(state["dh_local_pub"])
        obj.dh_remote_pub = b64_decode(state["dh_remote_pub"]) if state.get("dh_remote_pub") else None
        obj.send_count = state.get("send_count", 0)
        obj.recv_count = state.get("recv_count", 0)
        obj.skipped_message_keys = {}
        return obj
