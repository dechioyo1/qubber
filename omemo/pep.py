import xml.etree.ElementTree as ET
import logging

NS_AXOLOTL = 'eu.siacs.conversations.axolotl'
NS_OMEMO_2 = 'urn:xmpp:omemo:2'
NS_PUBSUB = 'http://jabber.org/protocol/pubsub'

class OmemoPEP:
    @staticmethod
    def build_device_list_payload(device_id: int) -> tuple[ET.Element, ET.Element]:
        dev_id_str = str(device_id)
        logging.info(f"[OMEMO PEP] Serializing device list payload for Device ID {device_id}...")

        # 1. Legacy Conversations payload
        list_legacy = ET.Element(f'{{{NS_AXOLOTL}}}list')
        ET.SubElement(list_legacy, 'device', id=dev_id_str)

        # 2. XEP-0384 v2 payload
        list_v2 = ET.Element(f'{{{NS_OMEMO_2}}}devices')
        ET.SubElement(list_v2, 'device', id=dev_id_str)

        return list_legacy, list_v2

    @staticmethod
    def build_bundle_payload(bundle_data: dict) -> tuple[ET.Element, ET.Element]:
        logging.info(f"[OMEMO PEP] Serializing prekey bundle payload for Device ID (Prekeys count: {len(bundle_data['prekeys'])})...")
        # 1. Legacy Conversations payload
        b_legacy = ET.Element(f'{{{NS_AXOLOTL}}}bundle')
        
        spk_pub = ET.SubElement(b_legacy, 'signedPreKeyPublic', signedPreKeyId=str(bundle_data['signed_prekey_id']))
        spk_pub.text = bundle_data['signed_prekey']
        
        spk_sig = ET.SubElement(b_legacy, 'signedPreKeySignature')
        spk_sig.text = bundle_data['signed_prekey_sig']
        
        ik = ET.SubElement(b_legacy, 'identityKey')
        ik.text = bundle_data['identity_key']
        
        pks = ET.SubElement(b_legacy, 'prekeys')
        for pk in bundle_data['prekeys']:
            pk_elem = ET.SubElement(pks, 'preKeyPublic', preKeyId=str(pk['id']))
            pk_elem.text = pk['public_key']

        # 2. XEP-0384 v2 payload
        b_v2 = ET.Element(f'{{{NS_OMEMO_2}}}bundle')
        
        spk_pub2 = ET.SubElement(b_v2, 'spk', id=str(bundle_data['signed_prekey_id']))
        spk_pub2.text = bundle_data['signed_prekey']
        
        spk_sig2 = ET.SubElement(b_v2, 'spks')
        spk_sig2.text = bundle_data['signed_prekey_sig']
        
        ik2 = ET.SubElement(b_v2, 'ik')
        ik2.text = bundle_data['identity_key']
        
        pk_container = ET.SubElement(b_v2, 'pk')
        for pk in bundle_data['prekeys']:
            pk_elem2 = ET.SubElement(pk_container, 'pk', id=str(pk['id']))
            pk_elem2.text = pk['public_key']

        return b_legacy, b_v2

    @staticmethod
    def parse_device_list(xml_elem) -> list[int]:
        device_ids = []
        if xml_elem is None:
            return device_ids
        for elem in xml_elem.iter():
            if elem.tag.endswith('device') and elem.get('id'):
                try:
                    device_ids.append(int(elem.get('id')))
                except ValueError:
                    pass
        logging.info(f"[OMEMO PEP] Parsed remote device list ({len(device_ids)} devices: {device_ids})")
        return device_ids

    @staticmethod
    def parse_bundle(xml_elem) -> dict:
        bundle = {}
        if xml_elem is None:
            return bundle
        for elem in xml_elem.iter():
            tag = elem.tag
            if (tag.endswith('identityKey') or tag.endswith('ik') or tag.endswith('publicKey')) and elem.text:
                bundle['identity_key'] = elem.text.strip()
            elif (tag.endswith('signedPreKeyPublic') or tag.endswith('spk') or tag.endswith('signedPreKey')) and elem.text:
                bundle['signed_prekey'] = elem.text.strip()
            elif (tag.endswith('signedPreKeySignature') or tag.endswith('spks') or tag.endswith('signature')) and elem.text:
                bundle['signed_prekey_sig'] = elem.text.strip()
        logging.info(f"[OMEMO PEP] Parsed remote prekey bundle (IK={bundle.get('identity_key')[:12] if bundle.get('identity_key') else 'None'}...)")
        return bundle
