import sys
import os
import asyncio
import logging
import base64
import xml.etree.ElementTree as ET
from PySide6.QtCore import QSettings, QCoreApplication, QStandardPaths
from PySide6.QtWidgets import QApplication

sys.path.insert(0, os.path.dirname(__file__))

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)-8s %(message)s")

import slixmpp
import keyring
from qubber_omemo.manager import OmemoManager
from qubber_omemo.pep import OmemoPEP
from qubber_omemo.crypto import generate_x25519_keypair, sign_ed25519, b64_decode, b64_encode

KEYRING_SERVICE = "Qubber"

app = QApplication.instance() or QApplication(sys.argv)
settings = QSettings("Qubber", "QubberApp")
jid = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("XMPP_JID", settings.value("jid", ""))
password = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("XMPP_PASSWORD", "")

if not password and jid:
    try:
        password = keyring.get_password(KEYRING_SERVICE, jid) or ""
    except Exception as e:
        print(f"Keyring error: {e}")

if not jid or not password:
    print("❌ Usage: python3 test_send_omemo_device_by_device.py <JID> <PASSWORD>")
    print("   Or set XMPP_JID and XMPP_PASSWORD environment variables.")
    sys.exit(1)

print(f"🔑 Loaded Credentials: JID={jid}")

target_jid = "dechioyo@disroot.org"

class OmemoTestClient(slixmpp.ClientXMPP):
    def __init__(self, jid, password):
        super().__init__(jid, password)
        self.register_plugin('xep_0030')
        self.register_plugin('xep_0060')
        self.register_plugin('xep_0163')
        self.register_plugin('xep_0280')
        self.register_plugin('xep_0334')
        self.add_event_handler("session_start", self.start_tests)
        self.omemo_mgr = OmemoManager()

    async def start_tests(self, event):
        self.send_presence()
        await self.get_roster()

        print(f"\n[1] Fetching OMEMO device list for target JID: {target_jid}...")
        device_ids = []
        for node in ['eu.siacs.conversations.axolotl.devicelist', 'urn:xmpp:omemo:2:devices']:
            try:
                res = await self['xep_0060'].get_items(target_jid, node)
                xml_obj = res.xml if hasattr(res, 'xml') else None
                parsed = OmemoPEP.parse_device_list(xml_obj)
                if parsed:
                    device_ids = parsed
                    print(f"  • Found {len(device_ids)} device IDs on node '{node}': {device_ids}")
                    break
            except Exception as e:
                print(f"  • Could not fetch node '{node}': {e}")

        if not device_ids:
            print("❌ No target device IDs found on PEP!")
            self.disconnect()
            return

        print(f"\n[2] Downloading prekey bundles for all {len(device_ids)} devices...")
        bundles = {}
        for dev_id in device_ids:
            parsed_bundle = {}
            for item_id in [None, 'current']:
                try:
                    kwargs = {'item_id': item_id} if item_id else {}
                    b_res = await self['xep_0060'].get_items(target_jid, f'eu.siacs.conversations.axolotl.bundles:{dev_id}', **kwargs)
                    xml_obj = b_res.xml if hasattr(b_res, 'xml') else None
                    parsed_bundle = OmemoPEP.parse_bundle(xml_obj)
                    if parsed_bundle.get('identity_key'):
                        break
                except Exception:
                    pass

            if not parsed_bundle.get('identity_key'):
                try:
                    b_res = await self['xep_0060'].get_items(target_jid, 'urn:xmpp:omemo:2:bundles', item_id=str(dev_id))
                    xml_obj = b_res.xml if hasattr(b_res, 'xml') else None
                    parsed_bundle = OmemoPEP.parse_bundle(xml_obj)
                except Exception:
                    pass

            if parsed_bundle.get('identity_key'):
                bundles[dev_id] = parsed_bundle
                print(f"  ✅ Received Bundle for Device ID {dev_id} (Prekey Count: {len(parsed_bundle.get('prekeys', []))})")
                self.omemo_mgr.store_peer_bundle(
                    peer_jid=target_jid,
                    device_id=dev_id,
                    identity_key_b64=parsed_bundle['identity_key'],
                    signed_prekey_b64=parsed_bundle['signed_prekey'],
                    signed_prekey_sig_b64=parsed_bundle['signed_prekey_sig']
                )
            else:
                print(f"  ⚠️ Could not fetch valid bundle for Device ID {dev_id}")

        print("\n" + "=" * 65)
        print("          DEVICE-BY-DEVICE OMEMO MESSAGE TRANSMISSION")
        print("=" * 65)

        for dev_id in bundles.keys():
            print(f"\n--> Sending OMEMO Test Message ONLY targeting Device ID: {dev_id}...")
            single_data, fallback = self.omemo_mgr.encrypt_payload(target_jid, f"Test Message to Device {dev_id}", target_device_ids=[dev_id])
            if single_data:
                msg = self.make_message(mto=target_jid, mbody=fallback, mtype='chat')
                msg['request_receipt'] = True

                enc_elem = ET.Element('{eu.siacs.conversations.axolotl}encrypted')
                header_elem = ET.SubElement(enc_elem, 'header', sid=str(single_data['sid']))
                for rid, key_info in single_data['keys'].items():
                    k_elem = ET.SubElement(header_elem, 'key', rid=str(rid))
                    if isinstance(key_info, dict):
                        if key_info.get('prekey'):
                            k_elem.set('prekey', 'true')
                        k_elem.text = key_info.get('key', '')
                    else:
                        k_elem.text = str(key_info)

                iv_elem = ET.SubElement(header_elem, 'iv')
                iv_elem.text = single_data['iv']
                payload_elem = ET.SubElement(enc_elem, 'payload')
                payload_elem.text = single_data['payload']

                msg.append(enc_elem)
                print(f"  • XML Stanza Sent: {ET.tostring(enc_elem, encoding='unicode')}")
                msg.send()
                await asyncio.sleep(2)

        print("\n--> Sending Combined OMEMO Test Message targeting ALL Devices...")
        multi_data, fallback = self.omemo_mgr.encrypt_payload(target_jid, "Test Message targeting ALL Devices", target_device_ids=list(bundles.keys()))
        if multi_data:
            msg = self.make_message(mto=target_jid, mbody=fallback, mtype='chat')
            msg['request_receipt'] = True

            enc_elem = ET.Element('{eu.siacs.conversations.axolotl}encrypted')
            header_elem = ET.SubElement(enc_elem, 'header', sid=str(multi_data['sid']))
            for rid, key_info in multi_data['keys'].items():
                k_elem = ET.SubElement(header_elem, 'key', rid=str(rid))
                if isinstance(key_info, dict):
                    if key_info.get('prekey'):
                        k_elem.set('prekey', 'true')
                    k_elem.text = key_info.get('key', '')
                else:
                    k_elem.text = str(key_info)

            iv_elem = ET.SubElement(header_elem, 'iv')
            iv_elem.text = multi_data['iv']
            payload_elem = ET.SubElement(enc_elem, 'payload')
            payload_elem.text = multi_data['payload']

            msg.append(enc_elem)
            print(f"  • XML Stanza Sent: {ET.tostring(enc_elem, encoding='unicode')}")
            msg.send()

        print("\n✅ All device-by-device test messages sent successfully!")
        await asyncio.sleep(3)
        self.disconnect()

async def main():
    client = OmemoTestClient(jid, password)
    client.connect()
    await client.disconnected

if __name__ == "__main__":
    asyncio.run(main())
