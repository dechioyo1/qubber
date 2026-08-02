import unittest
import tempfile
import os
import sqlite3
import xml.etree.ElementTree as ET
from PySide6.QtCore import QCoreApplication
import sys

from chat_model import ChatModel
from roster_model import RosterModel
from backend import XmppBackend

class TestXEP0308(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not QCoreApplication.instance():
            cls.app = QCoreApplication(sys.argv)

    def setUp(self):
        self.roster_model = RosterModel()
        self.chats_list_model = RosterModel()
        self.chat_model = ChatModel()
        self.backend = XmppBackend(self.roster_model, self.chats_list_model, self.chat_model)

    def test_chat_model_edit_and_get_last_my_message(self):
        self.chat_model.add_message('me', 'First message', '12:00', True, msg_id=1)
        self.chat_model.add_message('peer@example.com', 'Hello back', '12:01', False, msg_id=2)
        self.chat_model.add_message('me', 'Second message', '12:02', True, msg_id=3)

        # Test getLastMyMessage
        last_my_msg = self.chat_model.getLastMyMessage()
        self.assertEqual(last_my_msg.get('msgId'), 3)
        self.assertEqual(last_my_msg.get('body'), 'Second message')

        # Test update_message_body
        res = self.chat_model.update_message_body(3, 'Second message (edited)', is_edited=True)
        self.assertTrue(res)

        idx = self.chat_model.index(2, 0)
        self.assertEqual(self.chat_model.data(idx, self.chat_model.BodyRole), 'Second message (edited)')
        self.assertTrue(self.chat_model.data(idx, self.chat_model.IsEditedRole))

    def test_backend_edit_message_db_update(self):
        account_jid = 'user@example.com'
        peer_jid = 'peer@example.com'
        self.backend._active_chat_jid = peer_jid

        # Save an initial message
        msg_id = self.backend.save_message_to_db(account_jid, peer_jid, 'me', 'Original text', '12:00', True)
        self.assertIsNotNone(msg_id)

        self.chat_model.add_message('me', 'Original text', '12:00', True, msg_id=msg_id)

        # Execute editMessage
        self.backend.editMessage(msg_id, 'Edited text')

        # Verify DB update
        cursor = self.backend.db_conn.cursor()
        cursor.execute("SELECT body, is_edited FROM messages WHERE id = ?", (msg_id,))
        row = cursor.fetchone()
        self.assertEqual(row[0], 'Edited text')
        self.assertEqual(row[1], 1)

        # Verify chat model update
        idx = self.chat_model.index(0, 0)
        self.assertEqual(self.chat_model.data(idx, self.chat_model.BodyRole), 'Edited text')
        self.assertTrue(self.chat_model.data(idx, self.chat_model.IsEditedRole))

if __name__ == '__main__':
    unittest.main()
