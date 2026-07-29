import unittest
import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from omemo.crypto import (
    generate_identity_keypair,
    split_identity_key,
    sign_ed25519,
    verify_ed25519,
    format_fingerprint,
    b64_encode,
    b64_decode
)
from omemo.x3dh import X3DHAgreement
from omemo.manager import OmemoManager

class TestOmemoEngine(unittest.TestCase):
    def test_key_generation_and_signatures(self):
        priv_bytes, pub_bytes = generate_identity_keypair()
        self.assertEqual(len(priv_bytes), 64)
        self.assertEqual(len(pub_bytes), 64)

        ed_priv, x_priv = split_identity_key(priv_bytes)
        ed_pub, x_pub = split_identity_key(pub_bytes)
        self.assertEqual(len(ed_priv), 32)
        self.assertEqual(len(x_priv), 32)
        self.assertEqual(len(ed_pub), 32)
        self.assertEqual(len(x_pub), 32)

        message = b"Test signature payload"
        sig = sign_ed25519(ed_priv, message)
        self.assertTrue(verify_ed25519(ed_pub, sig, message))
        self.assertFalse(verify_ed25519(ed_pub, sig, b"Tampered payload"))

    def test_x3dh_agreement(self):
        alice_priv, alice_pub = generate_identity_keypair()
        bob_priv, bob_pub = generate_identity_keypair()

        # Bob prekey setup
        bob_ed_priv, _ = split_identity_key(bob_priv)
        from omemo.crypto import generate_x25519_keypair
        spk_priv, spk_pub = generate_x25519_keypair()
        spk_sig = sign_ed25519(bob_ed_priv, spk_pub)

        # Alice initiates
        master_sk_alice, alice_ek_pub, x3dh_header = X3DHAgreement.initiate(
            alice_ik_priv=alice_priv,
            bob_ik_pub=bob_pub,
            bob_spk_pub=spk_pub,
            bob_spk_sig=spk_sig
        )

        # Bob responds
        master_sk_bob = X3DHAgreement.respond(
            bob_ik_priv=bob_priv,
            bob_spk_priv=spk_priv,
            alice_ik_pub=alice_pub,
            alice_ek_pub=alice_ek_pub
        )

        self.assertEqual(master_sk_alice, master_sk_bob)

    def test_omemo_end_to_end_single_message(self):
        alice = OmemoManager(db_path=":memory:")
        bob = OmemoManager(db_path=":memory:")

        # Exchange bundles
        alice.store_peer_bundle("bob@test.org", bob.get_device_id(), bob.get_bundle_data()['identity_key'], bob.get_bundle_data()['signed_prekey'], bob.get_bundle_data()['signed_prekey_sig'])
        bob.store_peer_bundle("alice@test.org", alice.get_device_id(), alice.get_bundle_data()['identity_key'], alice.get_bundle_data()['signed_prekey'], alice.get_bundle_data()['signed_prekey_sig'])

        plaintext = "Top secret OMEMO payload 123"
        omemo_data, fallback = alice.encrypt_payload("bob@test.org", plaintext)
        self.assertIsNotNone(omemo_data)

        decrypted = bob.decrypt_payload("alice@test.org", omemo_data)
        self.assertEqual(decrypted, plaintext)

    def test_omemo_multi_turn_ratchet(self):
        alice = OmemoManager(db_path=":memory:")
        bob = OmemoManager(db_path=":memory:")

        alice.store_peer_bundle("bob@test.org", bob.get_device_id(), bob.get_bundle_data()['identity_key'], bob.get_bundle_data()['signed_prekey'], bob.get_bundle_data()['signed_prekey_sig'])
        bob.store_peer_bundle("alice@test.org", alice.get_device_id(), alice.get_bundle_data()['identity_key'], alice.get_bundle_data()['signed_prekey'], alice.get_bundle_data()['signed_prekey_sig'])

        msgs_alice = ["Msg 1 from Alice", "Msg 2 from Alice"]
        msgs_bob = ["Msg 1 reply from Bob", "Msg 2 reply from Bob"]

        # Alice -> Bob
        d1, _ = alice.encrypt_payload("bob@test.org", msgs_alice[0])
        self.assertEqual(bob.decrypt_payload("alice@test.org", d1), msgs_alice[0])

        # Bob -> Alice
        d2, _ = bob.encrypt_payload("alice@test.org", msgs_bob[0])
        self.assertEqual(alice.decrypt_payload("bob@test.org", d2), msgs_bob[0])

        # Alice -> Bob
        d3, _ = alice.encrypt_payload("bob@test.org", msgs_alice[1])
        self.assertEqual(bob.decrypt_payload("alice@test.org", d3), msgs_alice[1])

        # Bob -> Alice
        d4, _ = bob.encrypt_payload("alice@test.org", msgs_bob[1])
        self.assertEqual(alice.decrypt_payload("bob@test.org", d4), msgs_bob[1])

    def test_xml_stanza_roundtrip(self):
        alice = OmemoManager(db_path=":memory:")
        bob = OmemoManager(db_path=":memory:")

        alice.store_peer_bundle("bob@test.org", bob.get_device_id(), bob.get_bundle_data()['identity_key'], bob.get_bundle_data()['signed_prekey'], bob.get_bundle_data()['signed_prekey_sig'])
        omemo_data, _ = alice.encrypt_payload("bob@test.org", "XML test message")

        # Build XML element as in backend.py
        enc_elem = ET.Element('{eu.siacs.conversations.axolotl}encrypted')
        header_elem = ET.SubElement(enc_elem, 'header', sid=str(omemo_data['sid']))
        for rid, key_info in omemo_data['keys'].items():
            k_elem = ET.SubElement(header_elem, 'key', rid=str(rid))
            if isinstance(key_info, dict):
                if key_info.get('prekey'):
                    k_elem.set('prekey', 'true')
                if key_info.get('dh'):
                    k_elem.set('dh', key_info['dh'])
                if key_info.get('n') is not None:
                    k_elem.set('n', str(key_info['n']))
                if key_info.get('iv'):
                    k_elem.set('iv', key_info['iv'])
                if key_info.get('ek'):
                    k_elem.set('ek', key_info['ek'])
                if key_info.get('ik'):
                    k_elem.set('ik', key_info['ik'])
                k_elem.text = key_info.get('key', '')

        iv_elem = ET.SubElement(header_elem, 'iv')
        iv_elem.text = omemo_data['iv']
        payload_elem = ET.SubElement(enc_elem, 'payload')
        payload_elem.text = omemo_data['payload']

        # Parse XML element back as in backend.py
        parsed_keys_map = {}
        sid = header_elem.get('sid')
        iv_b64 = iv_elem.text
        payload_b64 = payload_elem.text

        for child in header_elem.findall('key'):
            rid = child.get('rid')
            k_data = {
                'key': child.text.strip() if child.text else '',
                'iv': child.get('iv'),
                'dh': child.get('dh'),
                'n': int(child.get('n')) if child.get('n') is not None else 0,
                'prekey': child.get('prekey') == 'true',
                'ek': child.get('ek'),
                'ik': child.get('ik')
            }
            parsed_keys_map[int(rid)] = k_data

        parsed_omemo_data = {
            'sid': sid,
            'iv': iv_b64,
            'payload': payload_b64,
            'keys': parsed_keys_map
        }

        decrypted = bob.decrypt_payload("alice@test.org", parsed_omemo_data)
        self.assertEqual(decrypted, "XML test message")

if __name__ == "__main__":
    unittest.main()
