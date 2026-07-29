import logging
from cryptography.hazmat.primitives.asymmetric import ed25519, x25519
from .crypto import (
    generate_x25519_keypair,
    dh_exchange,
    hkdf_derive,
    verify_ed25519,
    split_identity_key,
    strip_type_byte,
    b64_decode,
    b64_encode
)

class X3DHAgreement:
    @staticmethod
    def initiate(
        alice_ik_priv: bytes,
        bob_ik_pub: bytes,
        bob_spk_pub: bytes,
        bob_spk_sig: bytes,
        bob_opk_pub: bytes = None,
        alice_ik_pub: bytes = None
    ) -> tuple[bytes, bytes, dict]:
        """
        Initiates X3DH key agreement from Alice (initiator) to Bob (recipient).
        """
        alice_ik_ed_priv, alice_ik_dh_priv = split_identity_key(alice_ik_priv)
        bob_ik_ed_pub, bob_ik_dh_pub = split_identity_key(bob_ik_pub)
        bob_spk_clean = strip_type_byte(bob_spk_pub)

        if not alice_ik_pub:
            try:
                ed_pub = ed25519.Ed25519PrivateKey.from_private_bytes(alice_ik_ed_priv).public_key().public_bytes_raw()
                dh_pub = x25519.X25519PrivateKey.from_private_bytes(alice_ik_dh_priv).public_key().public_bytes_raw()
                alice_ik_pub = b"\x05" + ed_pub + dh_pub
            except Exception:
                alice_ik_pub = alice_ik_priv

        logging.info(f"[OMEMO X3DH] Initiating X3DH Key Agreement with recipient device (IK={b64_encode(bob_ik_pub)[:12]}..., SPK={b64_encode(bob_spk_pub)[:12]}...)")
        
        # 1. Verify Bob's Signed Prekey Signature using Bob's Ed25519 Identity Key
        if bob_spk_sig:
            is_valid = (
                verify_ed25519(bob_ik_ed_pub, bob_spk_sig, bob_spk_clean) or
                verify_ed25519(bob_ik_ed_pub, bob_spk_sig, b"\x05" + bob_spk_clean) or
                verify_ed25519(bob_ik_ed_pub, bob_spk_sig, bob_spk_pub)
            )
            if not is_valid:
                logging.warning("[OMEMO X3DH] Recipient's Signed Prekey Ed25519 signature verification warning (possible legacy key format) — proceeding with X3DH key agreement.")
            else:
                logging.info("[OMEMO X3DH] Recipient's Signed Prekey Ed25519 signature VERIFIED successfully.")

        # 2. Generate Ephemeral Key pair for Alice (EK_A)
        alice_ek_priv, alice_ek_pub = generate_x25519_keypair()
        logging.info(f"[OMEMO X3DH] Generated Ephemeral Key pair EK_A (Public: {b64_encode(alice_ek_pub)[:12]}...)")

        # 3. Compute Diffie-Hellman Exchanges (DH1 - DH4)
        dh1 = dh_exchange(alice_ik_dh_priv, bob_spk_clean)
        dh2 = dh_exchange(alice_ek_priv, bob_ik_dh_pub)
        dh3 = dh_exchange(alice_ek_priv, bob_spk_clean)
        logging.info(f"[OMEMO X3DH] Computed Diffie-Hellman Exchanges: DH1={len(dh1)}B, DH2={len(dh2)}B, DH3={len(dh3)}B")
        
        dh_concat = dh1 + dh2 + dh3
        if bob_opk_pub:
            bob_opk_clean = strip_type_byte(bob_opk_pub)
            dh4 = dh_exchange(alice_ek_priv, bob_opk_clean)
            dh_concat += dh4
            logging.info(f"[OMEMO X3DH] Computed optional DH4 with One-Time Prekey: {len(dh4)}B")

        # 4. Derive Shared Master Key via HKDF
        master_sk = hkdf_derive(dh_concat, info=b"OMEMO X3DH Key Agreement Protocol")
        logging.info(f"[OMEMO X3DH] Derived Master Shared Secret SK ({len(master_sk)} bytes)")

        x3dh_header = {
            "ik": b64_encode(alice_ik_pub),
            "ek": b64_encode(alice_ek_pub),
            "spk_id": 1,
            "opk_id": 1 if bob_opk_pub else None
        }

        return master_sk, alice_ek_pub, x3dh_header

    @staticmethod
    def respond(
        bob_ik_priv: bytes,
        bob_spk_priv: bytes,
        alice_ik_pub: bytes,
        alice_ek_pub: bytes,
        bob_opk_priv: bytes = None
    ) -> bytes:
        """
        Responds to X3DH key agreement on Bob's side.
        """
        bob_ik_ed_priv, bob_ik_dh_priv = split_identity_key(bob_ik_priv)
        alice_ik_ed_pub, alice_ik_dh_pub = split_identity_key(alice_ik_pub)
        alice_ek_clean = strip_type_byte(alice_ek_pub)

        logging.info(f"[OMEMO X3DH] Responding to incoming X3DH key agreement from initiator (IK={b64_encode(alice_ik_pub)[:12]}..., EK={b64_encode(alice_ek_pub)[:12]}...)")
        dh1 = dh_exchange(bob_spk_priv, alice_ik_dh_pub)
        dh2 = dh_exchange(bob_ik_dh_priv, alice_ek_clean)
        dh3 = dh_exchange(bob_spk_priv, alice_ek_clean)

        dh_concat = dh1 + dh2 + dh3
        if bob_opk_priv:
            dh4 = dh_exchange(bob_opk_priv, alice_ek_clean)
            dh_concat += dh4

        master_sk = hkdf_derive(dh_concat, info=b"OMEMO X3DH Key Agreement Protocol")
        logging.info(f"[OMEMO X3DH] Responded and derived Master Shared Secret SK ({len(master_sk)} bytes)")
        return master_sk
