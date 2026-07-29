import asyncio
import logging
import hashlib
import base64
from datetime import datetime, date
from PySide6.QtCore import QObject, Signal, Slot, Property, QSettings, QStandardPaths
import slixmpp
import sqlite3
import os
import urllib.parse
import urllib.request
import keyring
from keyring.errors import PasswordDeleteError
import xml.etree.ElementTree as ET
from pathlib import Path
import json
from slixmpp_omemo import XEP_0384, TrustLevel
from omemo.storage import Storage, Just, Nothing
from qubber_omemo.manager import OmemoManager
from qubber_omemo.pep import OmemoPEP

class JSONStorage(Storage):
    def __init__(self, file_path):
        super().__init__()
        self.file_path = Path(file_path)
        self.data = json.loads(self.file_path.read_text()) if self.file_path.exists() else {}

    async def _load(self, key):
        if key in self.data:
            return Just(self.data[key])
        return Nothing()

    async def _store(self, key, value):
        self.data[key] = value
        try:
            self.file_path.write_text(json.dumps(self.data))
        except Exception as e:
            logging.error(f"Failed to write OMEMO JSONStorage: {e}")

    async def _delete(self, key):
        self.data.pop(key, None)
        try:
            self.file_path.write_text(json.dumps(self.data))
        except Exception as e:
            logging.error(f"Failed to delete OMEMO JSONStorage key {key}: {e}")

class QubberOmemoPlugin(XEP_0384):
    def __init__(self, xmpp, config=None):
        super().__init__(xmpp, config)
        data_dir = QStandardPaths.writableLocation(QStandardPaths.AppLocalDataLocation)
        os.makedirs(data_dir, exist_ok=True)
        storage_path = Path(data_dir) / "omemo_store.json"
        self._storage = JSONStorage(storage_path)

    @property
    def storage(self):
        return self._storage

    @property
    def _btbv_enabled(self):
        return True

    async def _prompt_manual_trust(self, manually_trusted, identifier):
        try:
            session_manager = await self.get_session_manager()
            for device in manually_trusted:
                await session_manager.set_trust(
                    device.bare_jid,
                    device.identity_key,
                    TrustLevel.TRUSTED.value
                )
        except Exception as e:
            logging.error(f"Error auto-trusting OMEMO device: {e}")

try:
    slixmpp.plugins.register_plugin(QubberOmemoPlugin)
except Exception:
    pass

KEYRING_SERVICE = "Qubber"

def format_chat_list_time(created_at_val, default_time_str=""):
    if not created_at_val:
        return default_time_str
    dt = None
    if isinstance(created_at_val, str):
        try:
            dt = datetime.strptime(created_at_val.split('.')[0], "%Y-%m-%d %H:%M:%S")
        except ValueError:
            try:
                dt = datetime.fromisoformat(created_at_val)
            except ValueError:
                return default_time_str
    elif isinstance(created_at_val, datetime):
        dt = created_at_val

    if not dt:
        return default_time_str

    msg_date = dt.date()
    today = date.today()
    delta_days = (today - msg_date).days

    if delta_days == 0:
        return dt.strftime("%H:%M")
    elif 1 <= delta_days < 7:
        day_names = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        return day_names[msg_date.weekday()]
    else:
        return dt.strftime("%d.%m.%y")


def format_date_header(created_at_val):
    if not created_at_val:
        dt = datetime.now()
    elif isinstance(created_at_val, str):
        try:
            dt = datetime.strptime(created_at_val.split('.')[0], "%Y-%m-%d %H:%M:%S")
        except ValueError:
            try:
                dt = datetime.fromisoformat(created_at_val)
            except ValueError:
                dt = datetime.now()
    elif isinstance(created_at_val, datetime):
        dt = created_at_val
    else:
        dt = datetime.now()

    msg_date = dt.date()
    today = date.today()
    month_name = dt.strftime("%B")
    
    if msg_date.year == today.year:
        return f"{dt.day} {month_name}"
    else:
        return f"{dt.day} {month_name} {dt.year}"


class XmppBackend(QObject):
    connectionStatusChanged = Signal(str)
    activeChatJidChanged = Signal(str)
    myJidChanged = Signal(str)
    myPresenceChanged = Signal()
    activeChatDetailsChanged = Signal()
    subscriptionRequested = Signal(str)
    omemoDetailsChanged = Signal()

    def __init__(self, roster_model, chats_list_model, chat_model, parent=None):
        super().__init__(parent)
        self.roster_model = roster_model
        self.chats_list_model = chats_list_model
        self.chat_model = chat_model
        
        self._connection_status = "Disconnected"
        self._active_chat_jid = ""
        self._my_jid = ""
        self._my_status = "available"
        self._my_status_message = ""
        
        self.client = None
        
        # Message cache: {bare_jid: [messages]}
        self._chats = {}
        # Unread counts: {bare_jid: count}
        self._unread_counts = {}
        
        # Settings
        self.settings = QSettings("Qubber", "Qubber")
        self._temp_password = ""
        self._temp_remember_me = False
        self._temp_host = ""
        self._temp_port = ""
        self._typing_states = {}
        self._typing_timers = {}
        
        # Database, Cache & OMEMO Setup
        data_dir = QStandardPaths.writableLocation(QStandardPaths.AppLocalDataLocation)
        os.makedirs(data_dir, exist_ok=True)
        self.cache_dir = os.path.join(data_dir, "cache", "avatars")
        os.makedirs(self.cache_dir, exist_ok=True)
        self.db_path = os.path.join(data_dir, "qubber.db")
        self.db_conn = sqlite3.connect(self.db_path)
        self._init_db()
        
        self.omemo_mgr = OmemoManager(data_dir=data_dir)

    # --- Properties ---
    @Property(str, notify=connectionStatusChanged)
    def connectionStatus(self):
        return self._connection_status

    def set_connection_status(self, status):
        if self._connection_status != status:
            self._connection_status = status
            self.connectionStatusChanged.emit(status)

    @Property(str, notify=activeChatJidChanged)
    def activeChatJid(self):
        return self._active_chat_jid

    def set_active_chat_jid(self, jid):
        if self._active_chat_jid != jid:
            self._active_chat_jid = jid
            self.activeChatJidChanged.emit(jid)

    @Property(str, notify=myJidChanged)
    def myJid(self):
        return self._my_jid

    def set_my_jid(self, jid):
        if self._my_jid != jid:
            self._my_jid = jid
            self.myJidChanged.emit(jid)

    @Property(str, notify=myPresenceChanged)
    def myStatus(self):
        return self._my_status

    @Property(str, notify=myPresenceChanged)
    def myStatusMessage(self):
        return self._my_status_message

    @Property(str, notify=activeChatDetailsChanged)
    def activeChatAvatar(self):
        if not self._active_chat_jid:
            return ""
        return self._get_avatar_file(self._active_chat_jid)

    @Property(str, notify=activeChatDetailsChanged)
    def activeChatLastSeen(self):
        if not self._active_chat_jid:
            return ""
        if self.isContactTyping(self._active_chat_jid):
            return "typing..."
        status, status_msg = self._get_contact_presence(self._active_chat_jid)
        if status != 'offline':
            return status.capitalize() + (f" - {status_msg}" if status_msg else "")
        # Check DB for cached last_seen
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("SELECT last_seen FROM contacts WHERE jid = ?", (self._active_chat_jid,))
            row = cursor.fetchone()
            if row and row[0]:
                return row[0]
        except Exception:
            pass
        return "Offline"

    @Property(int, notify=omemoDetailsChanged)
    def omemoDeviceId(self):
        return self.omemo_mgr.get_device_id()

    @Property(str, notify=omemoDetailsChanged)
    def omemoFingerprint(self):
        return self.omemo_mgr.get_fingerprint()

    @Property(str, notify=activeChatDetailsChanged)
    def activeChatEncryptionMode(self):
        if not self._active_chat_jid:
            return "No Encryption"
        return "OMEMO" if self.omemo_mgr.is_encryption_enabled(self._active_chat_jid) else "No Encryption"

    @Slot(str, result=bool)
    def getEncryptionEnabled(self, jid):
        return self.omemo_mgr.is_encryption_enabled(jid)

    @Slot(str, bool)
    def setEncryptionEnabled(self, jid, enabled):
        self.omemo_mgr.set_encryption_enabled(jid, enabled)
        if enabled and self.client and self.client.is_connected():
            asyncio.create_task(self._fetch_omemo_peer_keys_async(jid))
        self.activeChatDetailsChanged.emit()

    @Slot(result=str)
    def getOmemoDbPath(self):
        return self.omemo_mgr.get_db_path()

    @Slot()
    def regenerateOmemoKeys(self):
        if self.omemo_mgr.regenerate_keys():
            self.omemoDetailsChanged.emit()
            if self.client and self.client.is_connected():
                asyncio.create_task(self._publish_omemo_device_list_async())
                asyncio.create_task(self._publish_omemo_bundle_async())

    @Slot(str, result=list)
    def getContactFingerprints(self, jid):
        return self.omemo_mgr.get_peer_fingerprints(jid)

    @Slot(str)
    def deleteContact(self, jid):
        if not jid:
            return
        bare_jid = jid.split('/')[0]
        logging.info(f"Deleting contact {bare_jid} from roster and DB...")
        
        # Send unsubscribed presence and remove from roster
        if self.client and self.client.is_connected():
            try:
                self.client.send_presence(ptype='unsubscribed', pto=bare_jid)
                self.client.send_presence(ptype='unsubscribe', pto=bare_jid)
            except Exception as e:
                logging.error(f"Error removing contact presence: {e}")
                
        # Remove from SQLite database
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("DELETE FROM contacts WHERE jid = ?", (bare_jid,))
            cursor.execute("DELETE FROM messages WHERE peer_jid = ?", (bare_jid,))
            self.db_conn.commit()
        except Exception as e:
            logging.error(f"Error deleting contact from DB: {e}")

        # Remove from models
        self.roster_model.clearUnread(bare_jid)
        self.chats_list_model.clearUnread(bare_jid)
        if self._active_chat_jid == bare_jid:
            self.set_active_chat_jid("")
            self.chat_model.clear()
        self.update_chats_list_model()

    @Slot(str, str)
    def renameContact(self, jid, new_name):
        if not jid or not new_name:
            return
        bare_jid = jid.split('/')[0]
        logging.info(f"Renaming contact {bare_jid} to {new_name}")
        
        # Update SQLite DB
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("""
                INSERT INTO contacts (jid, name) VALUES (?, ?)
                ON CONFLICT(jid) DO UPDATE SET name = excluded.name
            """, (bare_jid, new_name))
            self.db_conn.commit()
        except Exception as e:
            logging.error(f"Error renaming contact in DB: {e}")
            
        # Update models
        self.roster_model.update_contact(bare_jid, name=new_name)
        self.chats_list_model.update_contact(bare_jid, name=new_name)
        if self._active_chat_jid == bare_jid:
            self.activeChatDetailsChanged.emit()
            
    def _load_saved_credentials(self):
        """Loads credentials directly from application QSettings."""
        if getattr(self, '_credentials_loaded', False):
            return
        
        self._cached_saved_jid = self.settings.value("jid", "")
        self._cached_saved_password = self.settings.value("password", "")
        self._credentials_loaded = True

    # --- Saved Credentials Properties ---
    @Property(str)
    def savedJid(self):
        self._load_saved_credentials()
        return self._cached_saved_jid

    @Property(str)
    def savedPassword(self):
        if self.savedRememberMe:
            self._load_saved_credentials()
            return self._cached_saved_password
        return ""

    @Property(str)
    def savedHost(self):
        return self.settings.value("host", "")

    @Property(str)
    def savedPort(self):
        return self.settings.value("port", "")

    @Property(bool)
    def savedRememberMe(self):
        val = self.settings.value("remember_me", False)
        if isinstance(val, str):
            return val.lower() == 'true'
        return bool(val)

    # --- Slots ---
    @Slot(str, str, str, str, bool)
    def login(self, jid, password, host=None, port=None, remember_me=False):
        if self.client:
            self.logout()
            
        self.set_connection_status("Connecting...")
        self.set_my_jid(jid)
        
        # Save temporary credentials to store upon successful connection
        self._temp_password = password
        self._temp_remember_me = remember_me
        self._temp_host = host
        self._temp_port = port
        
        # Initialize client
        self.client = slixmpp.ClientXMPP(jid, password)
        # Explicitly assign loop to slixmpp
        self.client.loop = asyncio.get_running_loop()
        
        self.client.use_message_ids = True
        self.client.register_plugin('xep_0004') # Data Forms
        self.client.register_plugin('xep_0030') # Service Discovery
        self.client.register_plugin('xep_0054') # vCard-temp (Avatars)
        self.client.register_plugin('xep_0153') # vCard-Based Avatars
        self.client.register_plugin('xep_0084') # User Avatar
        self.client.register_plugin('xep_0012') # Last Activity
        self.client.register_plugin('xep_0085') # Chat State Notifications
        self.client.register_plugin('xep_0184') # Message Delivery Receipts
        self.client.plugin['xep_0184'].auto_ack = True
        self.client.plugin['xep_0184'].auto_request = False
        self.client.register_plugin('xep_0363') # HTTP File Upload
        self.client.register_plugin('xep_0060') # PubSub
        self.client.register_plugin('xep_0163') # PEP
        self.client.register_plugin('xep_0280') # Message Carbons
        self.client.register_plugin('xep_0334') # Message Processing Hints
        try:
            self.client.register_plugin('xep_0384', pconfig={'fallback_message': '🔒 OMEMO encrypted message'})
            logging.info("slixmpp-omemo xep_0384 plugin registered successfully.")
        except Exception as e:
            logging.error(f"Failed to register xep_0384 plugin: {e}")
        
        # Register handlers
        self.client.add_event_handler("session_start", self._on_session_start)
        self.client.add_event_handler("message", self._on_message)
        self.client.add_event_handler("receipt_received", self._on_receipt_received)
        self.client.add_event_handler("changed_status", self._on_presence_change)
        self.client.add_event_handler("presence_subscribe", self._on_subscribe_request)
        self.client.add_event_handler("failed_auth", self._on_failed_auth)
        self.client.add_event_handler("disconnected", self._on_disconnected)
        self.client.add_event_handler("connection_failed", self._on_connection_failed)
        self.client.add_event_handler("chatstate_composing", self._on_chatstate_event)
        self.client.add_event_handler("chatstate_paused", self._on_chatstate_event)
        self.client.add_event_handler("chatstate_active", self._on_chatstate_event)
        self.client.add_event_handler("chatstate_inactive", self._on_chatstate_event)
        self.client.add_event_handler("chatstate_gone", self._on_chatstate_event)
        
        # Connect
        p = int(port) if port else None
        h = host if host else None
                
        # Perform connection
        try:
            logging.info(f"Initiating connection to XMPP server (host={h}, port={p})...")
            connected = self.client.connect(host=h, port=p)
            if not connected:
                self.set_connection_status("Connection failed to initiate.")
                logging.error("Connection failed to initiate.")
        except Exception as e:
            self.set_connection_status(f"Error: {str(e)}")
            logging.error(f"Connection exception: {str(e)}", exc_info=True)

    @Slot()
    def logout(self):
        if self.client and self.client.is_connected():
            try:
                logging.info("Sending unavailable presence before disconnect...")
                self.client.send_presence(ptype='unavailable')
                self.client.disconnect(wait=1.0)
            except Exception as e:
                logging.error(f"Error sending unavailable presence: {e}")
            finally:
                self.client = None
        self.set_connection_status("Disconnected")
        self.roster_model.clear()
        self.chats_list_model.clear()
        self.chat_model.clear()
        self._chats.clear()
        self._unread_counts.clear()
        self.set_active_chat_jid("")

    @Slot(str)
    def selectChat(self, jid):
        self.set_active_chat_jid(jid)
        self.activeChatDetailsChanged.emit()
        # Clear unread count
        self._unread_counts[jid] = 0
        self.roster_model.clearUnread(jid)
        self.chats_list_model.clearUnread(jid)
        
        # Spawns async fetch for avatar, last seen, and OMEMO keys if needed
        asyncio.create_task(self._fetch_avatar_async(jid))
        if self.omemo_mgr.is_encryption_enabled(jid) and self.client and self.client.is_connected():
            asyncio.create_task(self._fetch_omemo_peer_keys_async(jid))
        status, _ = self._get_contact_presence(jid)
        if status == 'offline':
            asyncio.create_task(self._fetch_last_seen_async(jid))
        
        # Load conversation from DB
        my_bare_jid = self.client.boundjid.bare if (self.client and self.client.boundjid) else self._my_jid.split('/')[0]
        msgs = self.load_messages_from_db(my_bare_jid, jid)
        self._chats[jid] = msgs
        self.chat_model.set_messages(msgs)

    @Slot(str)
    def sendMessage(self, body):
        if not self.client or not self._active_chat_jid or not body.strip():
            return
            
        mto = self._active_chat_jid
        logging.info(f"Sending message to {mto}: {body}")
        
        now_dt = datetime.now()
        timestamp = now_dt.strftime("%H:%M")
        created_at_str = now_dt.strftime("%Y-%m-%d %H:%M:%S")
        date_hdr = format_date_header(now_dt)
        my_bare_jid = self.client.boundjid.bare
        
        is_encrypted = self.omemo_mgr.is_encryption_enabled(mto)
        
        # Save to database with 'sending' status initially
        msg_id = self.save_message_to_db(my_bare_jid, mto, 'me', body, timestamp, True, status='sending', created_at=created_at_str, is_encrypted=is_encrypted)
        
        msg_entry = {
            'sender': 'me',
            'body': body,
            'timestamp': timestamp,
            'isMe': True,
            'status': 'sending',
            'isEncrypted': is_encrypted
        }
        if mto not in self._chats:
            self._chats[mto] = []
        self._chats[mto].append(msg_entry)
        
        self.chat_model.add_message('me', body, timestamp, True, msg_id=msg_id, status='sending', date_header=date_hdr, is_encrypted=is_encrypted)
        self.update_chats_list_model()
        
        # Asynchronously fetch keys if needed and send stanza
        asyncio.create_task(self._send_message_async(mto, body, msg_id))

    async def _send_message_async(self, mto, body, msg_id):
        status = 'sent'
        try:
            msg = self.client.make_message(mto=mto, mbody=body, mtype='chat')
            msg['id'] = str(msg_id)
            msg['request_receipt'] = True

            if self.omemo_mgr.is_encryption_enabled(mto):
                if self.client and 'xep_0384' in self.client.plugin:
                    try:
                        encrypted_msg, errors = await self.client.plugin['xep_0384'].encrypt_message(msg, mto)
                        if encrypted_msg:
                            msg = encrypted_msg
                            logging.info(f"Successfully encrypted OMEMO message via xep_0384 for {mto}")
                        if errors:
                            logging.warning(f"xep_0384 encryption non-critical info: {errors}")
                    except Exception as e:
                        logging.error(f"xep_0384 encryption exception for {mto}: {e}", exc_info=True)
                        # Fallback to custom payload if xep_0384 fails
                        peer_fps = self.omemo_mgr.get_peer_fingerprints(mto)
                        if not peer_fps:
                            await self._fetch_omemo_peer_keys_async(mto)
                        omemo_data, fallback = self.omemo_mgr.encrypt_payload(mto, body)
                        if omemo_data:
                            msg = self.client.make_message(mto=mto, mbody=fallback, mtype='chat')
                            msg['id'] = str(msg_id)
                            msg['request_receipt'] = True
                            enc_elem = ET.Element('{eu.siacs.conversations.axolotl}encrypted')
                            header_elem = ET.SubElement(enc_elem, 'header', sid=str(omemo_data['sid']))
                            for rid, key_info in omemo_data['keys'].items():
                                k_elem = ET.SubElement(header_elem, 'key', rid=str(rid))
                                if isinstance(key_info, dict):
                                    if key_info.get('prekey'):
                                        k_elem.set('prekey', 'true')
                                    k_elem.text = key_info.get('key', '')
                            iv_elem = ET.SubElement(header_elem, 'iv')
                            iv_elem.text = omemo_data['iv']
                            payload_elem = ET.SubElement(enc_elem, 'payload')
                            payload_elem.text = omemo_data['payload']
                            msg.append(enc_elem)

            msg.send()
        except Exception as e:
            logging.error(f"Failed to send message over socket: {e}")
            status = 'error'

        # Update status locally in DB and model
        if msg_id:
            try:
                cursor = self.db_conn.cursor()
                cursor.execute("UPDATE messages SET status = ? WHERE id = ?", (status, msg_id))
                self.db_conn.commit()
                self.chat_model.update_message_status(msg_id, status)
            except Exception as e:
                logging.error(f"Failed to update status in DB: {e}")
                
        self.update_chats_list_model()

    @Slot(str)
    def uploadFile(self, file_url):
        # Run upload in background async task
        asyncio.create_task(self._upload_file_async(file_url))

    async def _upload_file_async(self, file_url):
        # Convert file_url (e.g. file:///path/to/image.png) to local filesystem path
        parsed = urllib.parse.urlparse(file_url)
        local_path = urllib.request.url2pathname(parsed.path)
        
        logging.info(f"Initiating HTTP File Upload for local path: {local_path}")
        
        try:
            if not self.client or not self.client.is_connected():
                raise Exception("Not connected to XMPP server")
                
            # Perform upload via slixmpp xep_0363 plugin
            download_url = await self.client['xep_0363'].upload_file(local_path)
            logging.info(f"File uploaded successfully! URL: {download_url}")
            
            # Send the URL as a normal chat message
            self.sendMessage(download_url)
            
        except Exception as e:
            logging.error(f"HTTP File Upload failed: {e}", exc_info=True)
            # Log error locally so user sees the failure
            now_dt = datetime.now()
            timestamp = now_dt.strftime("%H:%M")
            created_at_str = now_dt.strftime("%Y-%m-%d %H:%M:%S")
            date_hdr = format_date_header(now_dt)
            my_bare_jid = self.client.boundjid.bare
            mto = self._active_chat_jid
            if mto:
                msg_id = self.save_message_to_db(my_bare_jid, mto, 'me', f"Failed to upload file: {e}", timestamp, True, status='error', created_at=created_at_str)
                self.chat_model.add_message('me', f"Failed to upload file: {e}", timestamp, True, msg_id=msg_id, status='error', date_header=date_hdr)
                self.update_chats_list_model()

    @Slot(str, str)
    def addContact(self, jid, nickname=""):
        if not self.client:
            return
        # Add to server roster
        self.client.update_roster(jid=jid, name=nickname)
        # Request subscription
        self.client.send_presence(ptype='subscribe', pto=jid)
        # Add to local model immediately
        self.roster_model.add_contact(jid=jid, name=nickname, status='offline')

    @Slot(str, str)
    def changePresence(self, show, status_msg):
        self._my_status = show
        self._my_status_message = status_msg
        self.myPresenceChanged.emit()
        if not self.client:
            return
        pshow = None if show == "available" else show
        self.client.send_presence(pshow=pshow, pstatus=status_msg)

    @Slot(str)
    def approveSubscription(self, jid):
        if not self.client:
            return
        # Send subscribed back
        self.client.send_presence(ptype='subscribed', pto=jid)
        # Also subscribe to their presence mutually if not already
        self.client.send_presence(ptype='subscribe', pto=jid)

    @Slot(str)
    def denySubscription(self, jid):
        if not self.client:
            return
        self.client.send_presence(ptype='unsubscribed', pto=jid)

    # --- Slixmpp Event Handlers ---
    async def _on_session_start(self, event):
        logging.info("XMPP Session started successfully.")
        self.set_connection_status("Connected")
        
        # Save credentials to settings
        self.save_credentials(
            self.client.boundjid.bare,
            self._temp_password,
            self._temp_host,
            self._temp_port,
            self._temp_remember_me
        )
        
        # Send initial presence
        self.client.send_presence()
        
        # Publish OMEMO device list and key bundle to PEP
        asyncio.create_task(self._publish_omemo_device_list_async())
        asyncio.create_task(self._publish_omemo_bundle_async())

        # Fetch roster
        try:
            logging.info("Requesting contact roster...")
            await self.client.get_roster()
            self._update_roster_model()
        except Exception as e:
            logging.error(f"Failed to retrieve roster: {e}", exc_info=True)

    async def _publish_omemo_device_list_async(self):
        if not self.client or not self.client.is_connected():
            return
        try:
            device_id = self.omemo_mgr.get_device_id()
            logging.info(f"Publishing OMEMO Device ID {device_id} to PEP...")
            item_legacy, item_v2 = OmemoPEP.build_device_list_payload(device_id)
            
            # Construct publish options for open access model
            pub_opts = None
            try:
                pub_opts = self.client.plugin['xep_0004'].make_form('submit', 'http://jabber.org/protocol/pubsub#publish-options')
                pub_opts.add_field(var='FORM_TYPE', type='hidden', value='http://jabber.org/protocol/pubsub#publish-options')
                pub_opts.add_field(var='pubsub#access_model', value='open')
            except Exception:
                pass
            
            await self.client['xep_0060'].publish(self.client.boundjid.bare, 'eu.siacs.conversations.axolotl.devicelist', id='current', payload=item_legacy, options=pub_opts)
            await self.client['xep_0060'].publish(self.client.boundjid.bare, 'urn:xmpp:omemo:2:devices', id='current', payload=item_v2, options=pub_opts)
            logging.info("OMEMO Device lists published successfully to PEP (access_model=open).")
        except Exception as e:
            logging.debug(f"PEP OMEMO Device list publish info: {e}")

    async def _publish_omemo_bundle_async(self):
        if not self.client or not self.client.is_connected():
            return
        try:
            device_id = self.omemo_mgr.get_device_id()
            bundle = self.omemo_mgr.get_bundle_data()
            item_legacy, item_v2 = OmemoPEP.build_bundle_payload(bundle)
            
            pub_opts = None
            try:
                pub_opts = self.client.plugin['xep_0004'].make_form('submit', 'http://jabber.org/protocol/pubsub#publish-options')
                pub_opts.add_field(var='FORM_TYPE', type='hidden', value='http://jabber.org/protocol/pubsub#publish-options')
                pub_opts.add_field(var='pubsub#access_model', value='open')
            except Exception:
                pass
            
            # OMEMO 0.3 (Legacy Conversations): node='eu.siacs.conversations.axolotl.bundles:{device_id}', item_id='current'
            await self.client['xep_0060'].publish(self.client.boundjid.bare, f'eu.siacs.conversations.axolotl.bundles:{device_id}', id='current', payload=item_legacy, options=pub_opts)
            # OMEMO 2.0: node='urn:xmpp:omemo:2:bundles', item_id=str(device_id)
            await self.client['xep_0060'].publish(self.client.boundjid.bare, 'urn:xmpp:omemo:2:bundles', id=str(device_id), payload=item_v2, options=pub_opts)
            logging.info(f"Published valid OMEMO signed prekey bundles for device {device_id} to PEP (access_model=open).")
        except Exception as e:
            logging.debug(f"PEP OMEMO Bundle publish info: {e}")

    async def _fetch_omemo_peer_keys_async(self, peer_jid):
        if not self.client or not self.client.is_connected() or not peer_jid:
            return
        bare_jid = peer_jid.split('/')[0]
        try:
            logging.info(f"Querying OMEMO device list for {bare_jid}...")
            device_ids = []
            
            for node in ['eu.siacs.conversations.axolotl.devicelist', 'urn:xmpp:omemo:2:devices']:
                try:
                    res = await self.client['xep_0060'].get_items(bare_jid, node)
                    xml_obj = res.xml if hasattr(res, 'xml') else None
                    device_ids = OmemoPEP.parse_device_list(xml_obj)
                    if device_ids:
                        break
                except Exception as ex1:
                    logging.debug(f"Query PEP node {node} without item_id failed: {ex1}")

                if not device_ids:
                    try:
                        res = await self.client['xep_0060'].get_items(bare_jid, node, item_id='current')
                        xml_obj = res.xml if hasattr(res, 'xml') else None
                        device_ids = OmemoPEP.parse_device_list(xml_obj)
                        if device_ids:
                            break
                    except Exception as ex2:
                        logging.debug(f"Query PEP node {node} with item_id='current' failed: {ex2}")

            logging.info(f"Retrieved OMEMO device IDs for {bare_jid}: {device_ids}")
            
            bundles_fetched = 0
            for dev_id in device_ids:
                try:
                    parsed_bundle = {}
                    # Try 1: Legacy Conversations bundle node (eu.siacs.conversations.axolotl.bundles:{dev_id})
                    for item_id in [None, 'current']:
                        try:
                            kwargs = {'item_id': item_id} if item_id else {}
                            bundle_res = await self.client['xep_0060'].get_items(bare_jid, f'eu.siacs.conversations.axolotl.bundles:{dev_id}', **kwargs)
                            xml_obj = bundle_res.xml if hasattr(bundle_res, 'xml') else None
                            parsed_bundle = OmemoPEP.parse_bundle(xml_obj)
                            if parsed_bundle.get('identity_key'):
                                break
                        except Exception:
                            pass

                    # Try 2: OMEMO 2.0 bundle node (urn:xmpp:omemo:2:bundles with item_id=str(dev_id))
                    if not parsed_bundle.get('identity_key'):
                        try:
                            bundle_res = await self.client['xep_0060'].get_items(bare_jid, 'urn:xmpp:omemo:2:bundles', item_id=str(dev_id))
                            xml_obj = bundle_res.xml if hasattr(bundle_res, 'xml') else None
                            parsed_bundle = OmemoPEP.parse_bundle(xml_obj)
                        except Exception:
                            pass

                    if parsed_bundle.get('identity_key'):
                        self.omemo_mgr.store_peer_bundle(
                            bare_jid,
                            dev_id,
                            parsed_bundle.get('identity_key'),
                            parsed_bundle.get('signed_prekey'),
                            parsed_bundle.get('signed_prekey_sig')
                        )
                        bundles_fetched += 1
                        logging.info(f"Successfully stored peer OMEMO bundle for {bare_jid}:{dev_id}")
                except Exception as ex:
                    logging.debug(f"Could not fetch bundle for {bare_jid}:{dev_id}: {ex}")

            if bundles_fetched > 0 or len(device_ids) > 0:
                self.activeChatDetailsChanged.emit()
        except Exception as e:
            logging.debug(f"Querying OMEMO keys for {bare_jid}: {e}")

    @Slot(result=bool)
    def cleanOmemoKeys(self):
        logging.info("Cleaning all local and cached OMEMO keys on user request...")
        success = self.omemo_mgr.clear_all_keys()
        if success and self.client and self.client.is_connected():
            asyncio.create_task(self._publish_omemo_device_list_async())
            asyncio.create_task(self._publish_omemo_bundle_async())
            if self._active_chat_jid:
                asyncio.create_task(self._fetch_omemo_peer_keys_async(self._active_chat_jid))
        self.activeChatDetailsChanged.emit()
        return success

    def _update_roster_model(self):
        if not self.client or not self.client.boundjid:
            return
        roster_contacts = []
        my_bare = self.client.boundjid.bare
        roster = self.client.roster[my_bare]
        for jid in roster.keys():
            if jid == my_bare:
                continue
            name = roster[jid]['name'] or jid.split('@')[0]
            status, status_msg = self._get_contact_presence(jid)
            avatar = self._get_avatar_file(jid)
            last_seen = self._get_cached_last_seen(jid)
            
            roster_contacts.append({
                'jid': jid,
                'name': name,
                'status': status,
                'statusMessage': status_msg,
                'unreadCount': self._unread_counts.get(jid, 0),
                'avatar': avatar,
                'lastSeen': last_seen
            })
            
            # Fetch avatar and last_seen only if not already cached
            if not avatar:
                asyncio.create_task(self._fetch_avatar_async(jid))
            if status == 'offline' and not last_seen:
                asyncio.create_task(self._fetch_last_seen_async(jid))
                
        self.roster_model.set_contacts(roster_contacts)
        self.update_chats_list_model()

    def _on_chatstate_event(self, msg):
        sender = msg['from'].bare
        state = msg.get('chat_state', '')
        if state == 'composing':
            self._set_contact_typing(sender, True)
        else:
            self._set_contact_typing(sender, False)

    def _set_contact_typing(self, jid, is_typing):
        if not jid:
            return
        current = self._typing_states.get(jid, False)
        if current != is_typing:
            self._typing_states[jid] = is_typing
            self.roster_model.update_contact(jid, isTyping=is_typing)
            self.chats_list_model.update_contact(jid, isTyping=is_typing)
            if jid == self._active_chat_jid:
                self.activeChatDetailsChanged.emit()

        if jid in self._typing_timers and self._typing_timers[jid]:
            try:
                self._typing_timers[jid].cancel()
            except Exception:
                pass
            self._typing_timers[jid] = None

        if is_typing:
            try:
                loop = asyncio.get_running_loop()
                self._typing_timers[jid] = loop.call_later(6.0, lambda: self._set_contact_typing(jid, False))
            except Exception:
                pass

    @Slot(str, result=bool)
    def isContactTyping(self, jid):
        return self._typing_states.get(jid, False)

    @Slot(str, bool)
    def sendTypingNotification(self, jid, is_typing):
        if not self.client or not self.client.is_connected() or not jid:
            return
        try:
            state = 'composing' if is_typing else 'paused'
            msg = self.client.make_message(mto=jid, mtype='chat')
            msg['chat_state'] = state
            msg.send()
        except Exception as e:
            logging.debug(f"Failed to send typing notification: {e}")

    async def _on_message(self, msg):
        sender = msg['from'].bare
        
        # Check chat states embedded in message
        if 'chat_state' in msg and msg['chat_state']:
            st = msg['chat_state']
            self._set_contact_typing(sender, st == 'composing')

        if msg['type'] in ('chat', 'normal'):
            is_omemo_decrypted = False
            if self.client and 'xep_0384' in self.client.plugin:
                if self.client.plugin['xep_0384'].is_encrypted(msg):
                    try:
                        decrypted_msg, sender_info = await self.client.plugin['xep_0384'].decrypt_message(msg)
                        if decrypted_msg and decrypted_msg['body']:
                            msg['body'] = decrypted_msg['body']
                            is_omemo_decrypted = True
                            self.omemo_mgr.set_encryption_enabled(sender, True)
                            logging.info(f"Successfully decrypted incoming OMEMO message via xep_0384 from {sender}")
                    except Exception as e:
                        logging.error(f"xep_0384 decryption failed for message from {sender}: {e}")

            if not is_omemo_decrypted:
                xml_elem = msg.xml if hasattr(msg, 'xml') else None
                if xml_elem is not None:
                    enc_nodes = [e for e in xml_elem.iter() if e.tag.endswith('encrypted')]
                    if enc_nodes:
                        enc_node = enc_nodes[0]
                        sid = None
                        iv_b64 = None
                        payload_b64 = None
                        keys_map = {}
                        
                        for child in enc_node.iter():
                            if child.tag.endswith('header'):
                                sid = child.get('sid')
                            elif child.tag.endswith('key'):
                                rid = child.get('rid')
                                if rid:
                                    k_data = {
                                        'key': child.text.strip() if child.text else '',
                                        'iv': child.get('iv'),
                                        'dh': child.get('dh'),
                                        'n': int(child.get('n')) if child.get('n') is not None else 0,
                                        'prekey': child.get('prekey') == 'true',
                                        'ek': child.get('ek'),
                                        'ik': child.get('ik')
                                    }
                                    try:
                                        keys_map[int(rid)] = k_data
                                    except ValueError:
                                        keys_map[rid] = k_data
                            elif child.tag.endswith('iv') and child.text:
                                iv_b64 = child.text.strip()
                            elif child.tag.endswith('payload') and child.text:
                                payload_b64 = child.text.strip()
                                
                        omemo_data = {
                            'sid': sid,
                            'iv': iv_b64,
                            'payload': payload_b64,
                            'keys': keys_map
                        }
                        
                        decrypted_body = self.omemo_mgr.decrypt_payload(sender, omemo_data)
                        if decrypted_body:
                            msg['body'] = decrypted_body
                            is_omemo_decrypted = True
                            self.omemo_mgr.set_encryption_enabled(sender, True)
                            logging.info(f"Successfully decrypted incoming OMEMO message from {sender}")

        if msg['type'] in ('chat', 'normal') and msg['body']:
            self._set_contact_typing(sender, False)
            body = msg['body']
            logging.info(f"Received message from {sender}: {body}")
            now_dt = datetime.now()
            timestamp = now_dt.strftime("%H:%M")
            created_at_str = now_dt.strftime("%Y-%m-%d %H:%M:%S")
            date_hdr = format_date_header(now_dt)
            
            # Save to database (incoming messages are default to 'read' or 'sent', let's say 'read')
            my_bare_jid = self.client.boundjid.bare
            is_encrypted_flag = locals().get('is_omemo_decrypted', False)
            msg_id = self.save_message_to_db(my_bare_jid, sender, sender, body, timestamp, False, status='read', created_at=created_at_str, is_encrypted=is_encrypted_flag)
            
            msg_entry = {
                'sender': sender,
                'body': body,
                'timestamp': timestamp,
                'isMe': False,
                'status': 'read',
                'isEncrypted': is_encrypted_flag
            }
            
            if sender not in self._chats:
                self._chats[sender] = []
            self._chats[sender].append(msg_entry)
            
            if self._active_chat_jid == sender:
                self.chat_model.add_message(sender, body, timestamp, False, msg_id=msg_id, status='read', date_header=date_hdr, is_encrypted=is_encrypted_flag)
            else:
                self._unread_counts[sender] = self._unread_counts.get(sender, 0) + 1
                
                # Make sure contact is in roster
                if not self.roster_model.hasContact(sender):
                    name = sender.split('@')[0]
                    self.roster_model.add_contact(sender, name=name, status='online', unreadCount=self._unread_counts[sender])
                else:
                    self.roster_model.update_contact(sender, unreadCount=self._unread_counts[sender])

            self.update_chats_list_model()

    async def _on_receipt_received(self, msg):
        acked_msg_id_str = msg['receipt']
        sender = msg['from'].bare
        logging.info(f"Received delivery receipt for message ID {acked_msg_id_str} from {sender}")
        try:
            msg_id = int(acked_msg_id_str)
            cursor = self.db_conn.cursor()
            cursor.execute("UPDATE messages SET status = 'read' WHERE id = ?", (msg_id,))
            self.db_conn.commit()
            
            self.chat_model.update_message_status(msg_id, 'read')
            self.update_chats_list_model()
        except ValueError:
            pass

    async def _on_presence_change(self, presence):
        jid = presence['from'].bare
        if jid == self.client.boundjid.bare:
            return
            
        status, status_msg = self._get_contact_presence(jid)
        last_seen = ""
        if status == 'offline':
            last_seen = "Last seen just now"
            self._update_cached_last_seen(jid, last_seen)
            asyncio.create_task(self._fetch_last_seen_async(jid))
            
        if not self._get_avatar_file(jid):
            asyncio.create_task(self._fetch_avatar_async(jid))
            
        self.roster_model.update_contact(jid, status=status, statusMessage=status_msg, lastSeen=last_seen)
        self.chats_list_model.update_contact(jid, status=status, statusMessage=status_msg, lastSeen=last_seen)
        if jid == self._active_chat_jid:
            self.activeChatDetailsChanged.emit()

    async def _on_subscribe_request(self, presence):
        jid = presence['from'].bare
        logging.info(f"Received subscription request from {jid}")
        self.subscriptionRequested.emit(jid)

    async def _on_failed_auth(self, event):
        logging.error(f"XMPP Authentication failed: {event}")
        self.set_connection_status("Authentication failed")
        if self.client:
            self.client.disconnect()

    async def _on_disconnected(self, event):
        logging.info("Disconnected from XMPP server.")
        self.set_connection_status("Disconnected")

    async def _on_connection_failed(self, event):
        logging.error(f"XMPP Connection failed: {event}")
        self.set_connection_status("Connection failed")

    def _get_contact_presence(self, jid):
        try:
            roster_entry = self.client.roster[self.client.boundjid.bare][jid]
            resources = roster_entry.resources
            status = 'offline'
            status_msg = ''
            if resources:
                best_show = 'offline'
                best_resource = None
                for res, pres in resources.items():
                    show = pres.get('show')
                    if not show:
                        show = 'available'
                    
                    show_rank = {'available': 4, 'chat': 3, 'dnd': 2, 'away': 1, 'xa': 0, 'offline': -1}
                    if show_rank.get(show, 0) > show_rank.get(best_show, -1):
                        best_show = show
                        best_resource = pres
                
                if best_resource:
                    status = best_show
                    status_msg = best_resource.get('status', '')
            return status, status_msg
        except Exception:
            return 'offline', ''

    def save_credentials(self, jid, password, host, port, remember_me):
        self.settings.setValue("host", host or "")
        self.settings.setValue("port", port or "")
        self.settings.setValue("remember_me", remember_me)
        
        self._cached_saved_jid = jid if remember_me else ""
        self._cached_saved_password = password if remember_me else ""
        self._credentials_loaded = True

        if remember_me:
            self.settings.setValue("jid", jid)
            self.settings.setValue("password", password)
            logging.info("Credentials saved securely in application settings.")
        else:
            self.settings.remove("jid")
            self.settings.remove("password")
            logging.info("Cleared stored credentials.")
            
        self.settings.sync()

    def _get_avatar_file(self, jid):
        if not jid:
            return ""
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("SELECT avatar_path FROM contacts WHERE jid = ?", (jid,))
            row = cursor.fetchone()
            if row and row[0]:
                path = row[0].replace("file://", "")
                if os.path.exists(path):
                    return row[0]
        except Exception:
            pass
        safe_jid = hashlib.sha1(jid.encode('utf-8')).hexdigest()
        filepath = os.path.join(self.cache_dir, f"{safe_jid}.png")
        if os.path.exists(filepath):
            return "file://" + filepath
        return ""

    def _get_cached_last_seen(self, jid):
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("SELECT last_seen FROM contacts WHERE jid = ?", (jid,))
            row = cursor.fetchone()
            if row and row[0]:
                return row[0]
        except Exception:
            pass
        return ""

    def _update_cached_last_seen(self, jid, last_seen):
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("""
                INSERT INTO contacts (jid, last_seen) VALUES (?, ?)
                ON CONFLICT(jid) DO UPDATE SET last_seen = excluded.last_seen
            """, (jid, last_seen))
            self.db_conn.commit()
        except Exception as e:
            logging.debug(f"Failed to update last_seen in DB: {e}")

    async def _fetch_avatar_async(self, jid):
        if not self.client or not self.client.is_connected() or not jid:
            return
        if self._get_avatar_file(jid):
            return
        try:
            logging.info(f"Fetching vCard avatar for {jid}...")
            vcard = await self.client['xep_0054'].get_vcard(jid=jid)
            binval_text = None
            if vcard is not None:
                xml_elem = vcard.xml if hasattr(vcard, 'xml') else vcard
                for elem in xml_elem.iter():
                    if elem.tag.endswith('BINVAL') and elem.text:
                        binval_text = elem.text.strip()
                        break
            if binval_text:
                # Remove whitespace and newlines from base64 string
                clean_b64 = "".join(binval_text.split())
                raw_bytes = base64.b64decode(clean_b64)
                safe_jid = hashlib.sha1(jid.encode('utf-8')).hexdigest()
                filepath = os.path.join(self.cache_dir, f"{safe_jid}.png")
                with open(filepath, "wb") as f:
                    f.write(raw_bytes)
                avatar_url = "file://" + filepath
                logging.info(f"Successfully downloaded and cached avatar for {jid} to {filepath}")
                
                cursor = self.db_conn.cursor()
                cursor.execute("""
                    INSERT INTO contacts (jid, avatar_path) VALUES (?, ?)
                    ON CONFLICT(jid) DO UPDATE SET avatar_path = excluded.avatar_path
                """, (jid, avatar_url))
                self.db_conn.commit()
                
                self.roster_model.update_contact(jid, avatar=avatar_url)
                self.chats_list_model.update_contact(jid, avatar=avatar_url)
                if jid == self._active_chat_jid:
                    self.activeChatDetailsChanged.emit()
            else:
                logging.info(f"No photo BINVAL data found in vCard for {jid}")
        except Exception as e:
            logging.info(f"Could not fetch avatar for {jid}: {e}")

    async def _fetch_last_seen_async(self, jid):
        if not self.client or not self.client.is_connected():
            return
        try:
            iq = self.client.make_iq_get(to=jid)
            iq['query'] = 'jabber:iq:last'
            response = await iq.send()
            seconds = response['query']['seconds']
            if seconds is not None and seconds != '':
                secs = int(seconds)
                last_seen_str = self._format_last_seen(secs)
                self._update_cached_last_seen(jid, last_seen_str)
                self.roster_model.update_contact(jid, lastSeen=last_seen_str)
                self.chats_list_model.update_contact(jid, lastSeen=last_seen_str)
                if jid == self._active_chat_jid:
                    self.activeChatDetailsChanged.emit()
        except Exception as e:
            logging.debug(f"Could not query last activity for {jid}: {e}")

    def _format_last_seen(self, seconds):
        if seconds < 60:
            return "Last seen just now"
        mins = seconds // 60
        if mins < 60:
            return f"Last seen {mins}m ago"
        hours = mins // 60
        if hours < 24:
            return f"Last seen {hours}h ago"
        days = hours // 24
        return f"Last seen {days}d ago"

    def _init_db(self):
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    account_jid TEXT,
                    peer_jid TEXT,
                    sender TEXT,
                    body TEXT,
                    timestamp TEXT,
                    is_me INTEGER,
                    status TEXT DEFAULT 'sent',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS contacts (
                    jid TEXT PRIMARY KEY,
                    name TEXT,
                    avatar_path TEXT,
                    last_seen TEXT
                )
            """)
            
            cursor.execute("PRAGMA table_info(messages)")
            columns = [info[1] for info in cursor.fetchall()]
            if 'status' not in columns:
                cursor.execute("ALTER TABLE messages ADD COLUMN status TEXT DEFAULT 'sent'")
            if 'is_encrypted' not in columns:
                cursor.execute("ALTER TABLE messages ADD COLUMN is_encrypted INTEGER DEFAULT 0")

            cursor.execute("PRAGMA table_info(contacts)")
            contact_cols = [info[1] for info in cursor.fetchall()]
            if 'avatar_path' not in contact_cols:
                cursor.execute("ALTER TABLE contacts ADD COLUMN avatar_path TEXT")
            if 'last_seen' not in contact_cols:
                cursor.execute("ALTER TABLE contacts ADD COLUMN last_seen TEXT")
                
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_messages_chat 
                ON messages(account_jid, peer_jid)
            """)
            self.db_conn.commit()
            logging.info(f"Database initialized successfully at {self.db_path}")
        except Exception as e:
            logging.error(f"Failed to initialize database: {e}", exc_info=True)

    def save_message_to_db(self, account_jid, peer_jid, sender, body, timestamp, is_me, status='sent', created_at=None, is_encrypted=False):
        try:
            if not created_at:
                created_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            cursor = self.db_conn.cursor()
            cursor.execute("""
                INSERT INTO messages (account_jid, peer_jid, sender, body, timestamp, is_me, status, created_at, is_encrypted)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (account_jid, peer_jid, sender, body, timestamp, 1 if is_me else 0, status, created_at, 1 if is_encrypted else 0))
            self.db_conn.commit()
            return cursor.lastrowid
        except Exception as e:
            logging.error(f"Failed to save message to DB: {e}", exc_info=True)
            return None

    def load_messages_from_db(self, account_jid, peer_jid):
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("""
                SELECT id, sender, body, timestamp, is_me, status, created_at, is_encrypted 
                FROM messages 
                WHERE account_jid = ? AND peer_jid = ? 
                ORDER BY created_at ASC, id ASC
            """, (account_jid, peer_jid))
            rows = cursor.fetchall()
            messages = []
            for row in rows:
                created_at_val = row[6]
                is_enc = bool(row[7]) if len(row) > 7 and row[7] is not None else False
                messages.append({
                    'msgId': row[0],
                    'sender': row[1],
                    'body': row[2],
                    'timestamp': row[3],
                    'isMe': bool(row[4]),
                    'status': row[5] or 'sent',
                    'createdAt': created_at_val,
                    'dateHeader': format_date_header(created_at_val),
                    'isEncrypted': is_enc
                })
            return messages
        except Exception as e:
            logging.error(f"Failed to load messages from DB: {e}", exc_info=True)
            return []

    def update_chats_list_model(self):
        if not self.client:
            return
            
        my_bare_jid = self.client.boundjid.bare
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("SELECT DISTINCT peer_jid FROM messages WHERE account_jid = ?", (my_bare_jid,))
            rows = cursor.fetchall()
            active_jids = [row[0] for row in rows]
            
            roster = self.client.roster[my_bare_jid]
            
            chat_contacts = []
            for jid in active_jids:
                name = None
                status = 'offline'
                status_msg = ''
                
                if jid in roster:
                    name = roster[jid]['name'] or jid.split('@')[0]
                    status, status_msg = self._get_contact_presence(jid)
                else:
                    name = jid.split('@')[0]
                
                # Fetch last message details from SQLite DB
                cursor.execute("""
                    SELECT body, timestamp, is_me, status, id, created_at FROM messages 
                    WHERE account_jid = ? AND peer_jid = ? 
                    ORDER BY created_at DESC, id DESC LIMIT 1
                """, (my_bare_jid, jid))
                last_msg_row = cursor.fetchone()
                
                last_message = ""
                last_message_time = ""
                last_message_is_me = False
                last_message_status = "sent"
                last_msg_id = 0
                
                if last_msg_row:
                    last_message = last_msg_row[0] or ""
                    time_str = last_msg_row[1] or ""
                    created_at_val = last_msg_row[5]
                    last_message_time = format_chat_list_time(created_at_val, default_time_str=time_str)
                    last_message_is_me = bool(last_msg_row[2])
                    last_message_status = last_msg_row[3] or "sent"
                    last_msg_id = last_msg_row[4] or 0
                
                chat_contacts.append({
                    'jid': jid,
                    'name': name,
                    'status': status,
                    'statusMessage': status_msg,
                    'unreadCount': self._unread_counts.get(jid, 0),
                    'lastMessage': last_message,
                    'lastMessageTime': last_message_time,
                    'lastMessageIsMe': last_message_is_me,
                    'lastMessageStatus': last_message_status,
                    'lastMsgId': last_msg_id,
                    'avatar': self._get_avatar_file(jid),
                    'lastSeen': self._get_cached_last_seen(jid),
                    'isTyping': self._typing_states.get(jid, False)
                })
            
            self.chats_list_model.set_contacts(chat_contacts, sort_by_latest=True)
        except Exception as e:
            logging.error(f"Failed to populate chats list model: {e}", exc_info=True)

    @Slot(str)
    def copyToClipboard(self, text):
        try:
            from PySide6.QtGui import QGuiApplication
            clipboard = QGuiApplication.clipboard()
            if clipboard:
                clipboard.setText(text)
        except Exception as e:
            logging.error(f"Failed to copy to clipboard: {e}", exc_info=True)

    @Slot(int, int)
    def deleteMessage(self, msg_id, model_row):
        try:
            if msg_id:
                cursor = self.db_conn.cursor()
                cursor.execute("DELETE FROM messages WHERE id = ?", (msg_id,))
                self.db_conn.commit()
            
            # Remove from model
            self.chat_model.remove_message(model_row)
            
            # Refresh chats list model
            self.update_chats_list_model()
        except Exception as e:
            logging.error(f"Failed to delete message: {e}", exc_info=True)

    @Slot(result=str)
    def getClipboardImageOrFile(self):
        try:
            from PySide6.QtGui import QGuiApplication
            clipboard = QGuiApplication.clipboard()
            if not clipboard:
                return ""
            mime = clipboard.mimeData()
            if mime:
                if mime.hasImage():
                    img = clipboard.image()
                    if not img.isNull():
                        timestamp = int(datetime.now().timestamp())
                        temp_path = os.path.join(self.cache_dir, f"paste_{timestamp}.png")
                        img.save(temp_path, "PNG")
                        logging.info(f"Saved clipboard image to {temp_path}")
                        return "file://" + temp_path
                if mime.hasUrls():
                    urls = mime.urls()
                    if urls:
                        return urls[0].toString()
        except Exception as e:
            logging.error(f"Failed to check clipboard image/file: {e}", exc_info=True)
        return ""

    @Slot(str, result=str)
    def getFormattedFileSize(self, file_url):
        try:
            parsed = urllib.parse.urlparse(file_url)
            path = urllib.request.url2pathname(parsed.path)
            if os.path.exists(path):
                size = os.path.getsize(path)
                if size < 1024:
                    return f"{size} B"
                elif size < 1024 * 1024:
                    return f"{size / 1024:.1f} KB"
                else:
                    return f"{size / (1024 * 1024):.1f} MB"
        except Exception:
            pass
        return ""
