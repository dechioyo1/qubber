import os
import sys
import logging
import base64
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

logging.basicConfig(level=logging.INFO, format="%(levelname)-8s %(message)s")

from qubber_omemo.manager import OmemoManager
from qubber_omemo.pep import OmemoPEP
from qubber_omemo.crypto import b64_encode, b64_decode

def run_omemo_diagnostics():
    print("=" * 65)
    print("           QUBBER OMEMO ENCRYPTION & PEP DIAGNOSTICS")
    print("=" * 65)

    # 1. Initialize Sender & Recipient Managers
    print("\n[1] Initializing Local Sender & Remote Recipient OMEMO Instances...")
    alice = OmemoManager(db_path=":memory:")
    bob = OmemoManager(db_path=":memory:")

    print(f"  • Alice Device ID: {alice.get_device_id()} | Fingerprint: {alice.get_fingerprint()}")
    print(f"  • Bob Device ID:   {bob.get_device_id()}   | Fingerprint: {bob.get_fingerprint()}")

    # 2. Extract and Validate Prekey Bundles
    print("\n[2] Exporting Prekey Bundles & Verifying Wire Serialization...")
    bob_bundle = bob.get_bundle_data()
    print(f"  • Identity Key (B64 len {len(bob_bundle['identity_key'])}): {bob_bundle['identity_key'][:25]}...")
    print(f"  • Signed Prekey ID: {bob_bundle['signed_prekey_id']}")
    print(f"  • Prekeys Published: {len(bob_bundle['prekeys'])}")

    # 3. Store Peer Bundle and Initiate X3DH + Double Ratchet
    print("\n[3] Storing Peer Bundle & Performing X3DH Key Agreement...")
    alice.store_peer_bundle(
        peer_jid="bob@example.org",
        device_id=bob.get_device_id(),
        identity_key_b64=bob_bundle['identity_key'],
        signed_prekey_b64=bob_bundle['signed_prekey'],
        signed_prekey_sig_b64=bob_bundle['signed_prekey_sig']
    )

    plaintext = "Hello Bob! Testing OMEMO End-to-End Encryption."
    print(f"\n[4] Encrypting Message: '{plaintext}'")
    omemo_data, fallback = alice.encrypt_payload("bob@example.org", plaintext)

    if not omemo_data:
        print("❌ ERROR: Encryption failed!")
        return False

    print(f"  • Sender Device SID: {omemo_data['sid']}")
    print(f"  • IV (B64): {omemo_data['iv']}")
    print(f"  • Encrypted Payload (B64): {omemo_data['payload'][:30]}...")
    print(f"  • Recipient Key Count: {len(omemo_data['keys'])}")

    # 4. Decrypt Payload
    print("\n[5] Decrypting Payload on Bob's Device...")
    decrypted = bob.decrypt_payload("alice@example.org", omemo_data)

    print(f"  • Result: {decrypted}")
    if decrypted == plaintext:
        print("\n✅ SUCCESS: E2EE Payload Encryption & Decryption Verified 100%!")
        print("=" * 65)
        return True
    else:
        print("\n❌ FAILURE: Decrypted payload mismatch!")
        print("=" * 65)
        return False

if __name__ == "__main__":
    run_omemo_diagnostics()
