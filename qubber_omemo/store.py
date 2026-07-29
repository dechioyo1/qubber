import os
import json
import sqlite3
import logging
from PySide6.QtCore import QStandardPaths

class OmemoStore:
    def __init__(self, db_path=None):
        if not db_path:
            data_dir = QStandardPaths.writableLocation(QStandardPaths.AppLocalDataLocation)
            os.makedirs(data_dir, exist_ok=True)
            db_path = os.path.join(data_dir, "omemo.db")
        
        self.db_path = db_path
        self.conn = sqlite3.connect(self.db_path)
        self._init_db()

    def _init_db(self):
        try:
            cursor = self.conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS identity (
                    device_id INTEGER PRIMARY KEY,
                    pub_key BLOB,
                    priv_key BLOB,
                    fingerprint TEXT
                )
            """)
            
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS signed_prekeys (
                    id INTEGER PRIMARY KEY,
                    pub_key BLOB,
                    priv_key BLOB,
                    signature BLOB
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS prekeys (
                    id INTEGER PRIMARY KEY,
                    pub_key BLOB,
                    priv_key BLOB
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS sessions (
                    peer_jid TEXT,
                    device_id INTEGER,
                    state_json TEXT,
                    PRIMARY KEY(peer_jid, device_id)
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS chat_settings (
                    peer_jid TEXT PRIMARY KEY,
                    enabled INTEGER DEFAULT 0
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS bundles (
                    peer_jid TEXT,
                    device_id INTEGER,
                    identity_key TEXT,
                    signed_prekey TEXT,
                    signed_prekey_id INTEGER,
                    signed_prekey_sig TEXT,
                    prekeys TEXT,
                    PRIMARY KEY(peer_jid, device_id)
                )
            """)

            self.conn.commit()
            logging.info(f"OMEMO Store DB initialized at {self.db_path}")
        except Exception as e:
            logging.error(f"Failed to initialize OMEMO Store DB: {e}", exc_info=True)

    def load_identity(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT device_id, pub_key, priv_key, fingerprint FROM identity LIMIT 1")
        return cursor.fetchone()

    def save_identity(self, device_id, pub_key, priv_key, fingerprint):
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO identity (device_id, pub_key, priv_key, fingerprint)
            VALUES (?, ?, ?, ?)
        """, (device_id, pub_key, priv_key, fingerprint))
        self.conn.commit()

    def clear_identity_and_keys(self):
        cursor = self.conn.cursor()
        cursor.execute("DELETE FROM identity")
        cursor.execute("DELETE FROM signed_prekeys")
        cursor.execute("DELETE FROM prekeys")
        cursor.execute("DELETE FROM sessions")
        cursor.execute("DELETE FROM bundles")
        self.conn.commit()

    def save_signed_prekey(self, spk_id, pub_key, priv_key, signature):
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO signed_prekeys (id, pub_key, priv_key, signature)
            VALUES (?, ?, ?, ?)
        """, (spk_id, pub_key, priv_key, signature))
        self.conn.commit()

    def load_signed_prekey(self, spk_id=1):
        cursor = self.conn.cursor()
        cursor.execute("SELECT pub_key, priv_key, signature FROM signed_prekeys WHERE id = ?", (spk_id,))
        return cursor.fetchone()

    def save_prekeys(self, prekey_list): # list of (id, pub_key, priv_key)
        cursor = self.conn.cursor()
        for pk_id, pub, priv in prekey_list:
            cursor.execute("INSERT OR REPLACE INTO prekeys (id, pub_key, priv_key) VALUES (?, ?, ?)", (pk_id, pub, priv))
        self.conn.commit()

    def load_prekeys(self):
        cursor = self.conn.cursor()
        cursor.execute("SELECT id, pub_key, priv_key FROM prekeys")
        return cursor.fetchall()

    def save_session(self, peer_jid, device_id, state_dict):
        bare_jid = peer_jid.split('/')[0] if peer_jid else ""
        state_json = json.dumps(state_dict)
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO sessions (peer_jid, device_id, state_json)
            VALUES (?, ?, ?)
            ON CONFLICT(peer_jid, device_id) DO UPDATE SET state_json = excluded.state_json
        """, (bare_jid, device_id, state_json))
        self.conn.commit()

    def load_session(self, peer_jid, device_id):
        bare_jid = peer_jid.split('/')[0] if peer_jid else ""
        cursor = self.conn.cursor()
        cursor.execute("SELECT state_json FROM sessions WHERE peer_jid = ? AND device_id = ?", (bare_jid, device_id))
        row = cursor.fetchone()
        if row and row[0]:
            try:
                return json.loads(row[0])
            except Exception:
                pass
        return None

    def store_bundle(self, peer_jid, device_id, identity_key_b64, signed_prekey_b64, signed_prekey_sig_b64=None):
        if not peer_jid or not device_id or not identity_key_b64:
            return
        bare_jid = peer_jid.split('/')[0]
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO bundles (peer_jid, device_id, identity_key, signed_prekey, signed_prekey_id, signed_prekey_sig)
            VALUES (?, ?, ?, ?, 1, ?)
            ON CONFLICT(peer_jid, device_id) DO UPDATE SET
                identity_key = excluded.identity_key,
                signed_prekey = excluded.signed_prekey,
                signed_prekey_sig = excluded.signed_prekey_sig
        """, (bare_jid, device_id, identity_key_b64, signed_prekey_b64, signed_prekey_sig_b64))
        self.conn.commit()

    def load_peer_bundles(self, peer_jid):
        bare_jid = peer_jid.split('/')[0] if peer_jid else ""
        cursor = self.conn.cursor()
        cursor.execute("SELECT device_id, identity_key, signed_prekey, signed_prekey_sig FROM bundles WHERE peer_jid = ?", (bare_jid,))
        return cursor.fetchall()

    def load_peer_bundle(self, peer_jid, device_id):
        bare_jid = peer_jid.split('/')[0] if peer_jid else ""
        cursor = self.conn.cursor()
        cursor.execute("SELECT device_id, identity_key, signed_prekey, signed_prekey_sig FROM bundles WHERE peer_jid = ? AND device_id = ?", (bare_jid, device_id))
        return cursor.fetchone()

    def set_chat_encryption(self, peer_jid, enabled: bool):
        bare_jid = peer_jid.split('/')[0] if peer_jid else ""
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO chat_settings (peer_jid, enabled) VALUES (?, ?)
            ON CONFLICT(peer_jid) DO UPDATE SET enabled = excluded.enabled
        """, (bare_jid, 1 if enabled else 0))
        self.conn.commit()

    def is_chat_encryption_enabled(self, peer_jid) -> bool:
        bare_jid = peer_jid.split('/')[0] if peer_jid else ""
        cursor = self.conn.cursor()
        cursor.execute("SELECT enabled FROM chat_settings WHERE peer_jid = ?", (bare_jid,))
        row = cursor.fetchone()
        return bool(row[0]) if row else False
