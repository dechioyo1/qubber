import asyncio
import logging
from datetime import datetime
from PySide6.QtCore import QObject, Signal, Slot, Property, QSettings, QStandardPaths
import slixmpp
import sqlite3
import os

class XmppBackend(QObject):
    connectionStatusChanged = Signal(str)
    activeChatJidChanged = Signal(str)
    myJidChanged = Signal(str)
    subscriptionRequested = Signal(str)

    def __init__(self, roster_model, chats_list_model, chat_model, parent=None):
        super().__init__(parent)
        self.roster_model = roster_model
        self.chats_list_model = chats_list_model
        self.chat_model = chat_model
        
        self._connection_status = "Disconnected"
        self._active_chat_jid = ""
        self._my_jid = ""
        
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
        
        # Database Setup
        data_dir = QStandardPaths.writableLocation(QStandardPaths.AppLocalDataLocation)
        os.makedirs(data_dir, exist_ok=True)
        self.db_path = os.path.join(data_dir, "qubber.db")
        self.db_conn = sqlite3.connect(self.db_path)
        self._init_db()

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
            
    # --- Saved Credentials Properties ---
    @Property(str)
    def savedJid(self):
        return self.settings.value("jid", "")

    @Property(str)
    def savedPassword(self):
        if self.savedRememberMe:
            return self.settings.value("password", "")
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
        
        # Register handlers
        self.client.add_event_handler("session_start", self._on_session_start)
        self.client.add_event_handler("message", self._on_message)
        self.client.add_event_handler("changed_status", self._on_presence_change)
        self.client.add_event_handler("presence_subscribe", self._on_subscribe_request)
        self.client.add_event_handler("failed_auth", self._on_failed_auth)
        self.client.add_event_handler("disconnected", self._on_disconnected)
        self.client.add_event_handler("connection_failed", self._on_connection_failed)
        
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
        if self.client:
            self.client.disconnect()
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
        # Clear unread count
        self._unread_counts[jid] = 0
        self.roster_model.clearUnread(jid)
        self.chats_list_model.clearUnread(jid)
        
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
        # Send via slixmpp
        self.client.send_message(mto=mto, mbody=body, mtype='chat')
        
        # Log locally
        timestamp = datetime.now().strftime("%H:%M")
        my_bare_jid = self.client.boundjid.bare
        
        # Save to database
        msg_id = self.save_message_to_db(my_bare_jid, mto, 'me', body, timestamp, True)
        
        # Ensure recipient is in active chats list
        if not self.chats_list_model.hasContact(mto):
            roster = self.client.roster[my_bare_jid]
            name = None
            status = 'offline'
            status_msg = ''
            if mto in roster:
                name = roster[mto]['name'] or mto.split('@')[0]
                status, status_msg = self._get_contact_presence(mto)
            else:
                name = mto.split('@')[0]
            self.chats_list_model.add_contact(mto, name=name, status=status, statusMessage=status_msg)
        
        msg_entry = {
            'sender': 'me',
            'body': body,
            'timestamp': timestamp,
            'isMe': True
        }
        if mto not in self._chats:
            self._chats[mto] = []
        self._chats[mto].append(msg_entry)
        self.chat_model.add_message('me', body, timestamp, True, msg_id=msg_id)

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
        # Fetch roster
        try:
            logging.info("Requesting contact roster...")
            await self.client.get_roster()
        except Exception as e:
            logging.error(f"Failed to retrieve roster: {e}", exc_info=True)
            
        # Populate roster model
        roster_contacts = []
        roster = self.client.roster[self.client.boundjid.bare]
        for jid in roster.keys():
            if jid == self.client.boundjid.bare:
                continue
            name = roster[jid]['name'] or jid.split('@')[0]
            status, status_msg = self._get_contact_presence(jid)
            roster_contacts.append({
                'jid': jid,
                'name': name,
                'status': status,
                'statusMessage': status_msg,
                'unreadCount': self._unread_counts.get(jid, 0)
            })
        self.roster_model.set_contacts(roster_contacts)
        
        # Populate chats list model from SQLite database
        self.update_chats_list_model()

    async def _on_message(self, msg):
        if msg['type'] in ('chat', 'normal') and msg['body']:
            sender = msg['from'].bare
            body = msg['body']
            logging.info(f"Received message from {sender}: {body}")
            timestamp = datetime.now().strftime("%H:%M")
            
            # Save to database
            my_bare_jid = self.client.boundjid.bare
            msg_id = self.save_message_to_db(my_bare_jid, sender, sender, body, timestamp, False)
            
            msg_entry = {
                'sender': sender,
                'body': body,
                'timestamp': timestamp,
                'isMe': False
            }
            
            if sender not in self._chats:
                self._chats[sender] = []
            self._chats[sender].append(msg_entry)
            
            if self._active_chat_jid == sender:
                self.chat_model.add_message(sender, body, timestamp, False, msg_id=msg_id)
            else:
                self._unread_counts[sender] = self._unread_counts.get(sender, 0) + 1
                
                # Make sure contact is in roster
                if not self.roster_model.hasContact(sender):
                    name = sender.split('@')[0]
                    self.roster_model.add_contact(sender, name=name, status='online', unreadCount=self._unread_counts[sender])
                else:
                    self.roster_model.update_contact(sender, unreadCount=self._unread_counts[sender])

            # Ensure contact is in active chats list
            if not self.chats_list_model.hasContact(sender):
                roster = self.client.roster[my_bare_jid]
                name = None
                status = 'offline'
                status_msg = ''
                if sender in roster:
                    name = roster[sender]['name'] or sender.split('@')[0]
                    status, status_msg = self._get_contact_presence(sender)
                else:
                    name = sender.split('@')[0]
                self.chats_list_model.add_contact(sender, name=name, status=status, statusMessage=status_msg, unreadCount=self._unread_counts.get(sender, 0))
            else:
                self.chats_list_model.update_contact(sender, unreadCount=self._unread_counts.get(sender, 0))

    async def _on_presence_change(self, presence):
        jid = presence['from'].bare
        if jid == self.client.boundjid.bare:
            return
            
        status, status_msg = self._get_contact_presence(jid)
        self.roster_model.update_contact(jid, status=status, statusMessage=status_msg)
        self.chats_list_model.update_contact(jid, status=status, statusMessage=status_msg)

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
        self.settings.setValue("jid", jid)
        self.settings.setValue("host", host or "")
        self.settings.setValue("port", port or "")
        self.settings.setValue("remember_me", remember_me)
        if remember_me:
            self.settings.setValue("password", password)
        else:
            self.settings.remove("password")
        self.settings.sync()

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
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_messages_chat 
                ON messages(account_jid, peer_jid)
            """)
            self.db_conn.commit()
            logging.info(f"Database initialized successfully at {self.db_path}")
        except Exception as e:
            logging.error(f"Failed to initialize database: {e}", exc_info=True)

    def save_message_to_db(self, account_jid, peer_jid, sender, body, timestamp, is_me):
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("""
                INSERT INTO messages (account_jid, peer_jid, sender, body, timestamp, is_me)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (account_jid, peer_jid, sender, body, timestamp, 1 if is_me else 0))
            self.db_conn.commit()
            return cursor.lastrowid
        except Exception as e:
            logging.error(f"Failed to save message to DB: {e}", exc_info=True)
            return None

    def load_messages_from_db(self, account_jid, peer_jid):
        try:
            cursor = self.db_conn.cursor()
            cursor.execute("""
                SELECT id, sender, body, timestamp, is_me 
                FROM messages 
                WHERE account_jid = ? AND peer_jid = ? 
                ORDER BY created_at ASC, id ASC
            """, (account_jid, peer_jid))
            rows = cursor.fetchall()
            messages = []
            for row in rows:
                messages.append({
                    'msgId': row[0],
                    'sender': row[1],
                    'body': row[2],
                    'timestamp': row[3],
                    'isMe': bool(row[4])
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
                
                chat_contacts.append({
                    'jid': jid,
                    'name': name,
                    'status': status,
                    'statusMessage': status_msg,
                    'unreadCount': self._unread_counts.get(jid, 0)
                })
            
            self.chats_list_model.set_contacts(chat_contacts)
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
