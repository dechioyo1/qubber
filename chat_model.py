from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Slot

class ChatModel(QAbstractListModel):
    SenderRole = Qt.ItemDataRole.UserRole + 1
    BodyRole = Qt.ItemDataRole.UserRole + 2
    TimestampRole = Qt.ItemDataRole.UserRole + 3
    IsMeRole = Qt.ItemDataRole.UserRole + 4
    MsgIdRole = Qt.ItemDataRole.UserRole + 5
    StatusRole = Qt.ItemDataRole.UserRole + 6

    DateHeaderRole = Qt.ItemDataRole.UserRole + 7
    ShowDateHeaderRole = Qt.ItemDataRole.UserRole + 8
    IsEncryptedRole = Qt.ItemDataRole.UserRole + 9
    IsEditedRole = Qt.ItemDataRole.UserRole + 10

    def __init__(self, parent=None):
        super().__init__(parent)
        self._messages = []  # list of dicts

    def roleNames(self):
        return {
            self.SenderRole: b"sender",
            self.BodyRole: b"body",
            self.TimestampRole: b"timestamp",
            self.IsMeRole: b"isMe",
            self.MsgIdRole: b"msgId",
            self.StatusRole: b"status",
            self.DateHeaderRole: b"dateHeader",
            self.ShowDateHeaderRole: b"showDateHeader",
            self.IsEncryptedRole: b"isEncrypted",
            self.IsEditedRole: b"isEdited"
        }

    def rowCount(self, parent=QModelIndex()):
        if parent.isValid():
            return 0
        return len(self._messages)

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._messages)):
            return None
        
        msg = self._messages[index.row()]
        if role == self.SenderRole:
            return msg['sender']
        elif role == self.BodyRole:
            return msg['body']
        elif role == self.TimestampRole:
            return msg['timestamp']
        elif role == self.IsMeRole:
            return msg['isMe']
        elif role == self.MsgIdRole:
            return msg.get('msgId')
        elif role == self.StatusRole:
            return msg.get('status', 'sent')
        elif role == self.DateHeaderRole:
            return msg.get('dateHeader', '')
        elif role == self.ShowDateHeaderRole:
            return msg.get('showDateHeader', False)
        elif role == self.IsEncryptedRole:
            return msg.get('isEncrypted', False)
        elif role == self.IsEditedRole:
            return msg.get('isEdited', False)
        return None

    def set_messages(self, messages):
        """Set the entire message list for the current active chat."""
        self.beginResetModel()
        processed = []
        last_date_header = None
        for msg in messages:
            m = dict(msg)
            date_hdr = m.get('dateHeader', '')
            if date_hdr and date_hdr != last_date_header:
                m['showDateHeader'] = True
                last_date_header = date_hdr
            else:
                m['showDateHeader'] = False
            processed.append(m)
        self._messages = processed
        self.endResetModel()

    def add_message(self, sender, body, timestamp, is_me, msg_id=None, status='sent', date_header='', is_encrypted=False, is_edited=False):
        """Append a single message to the active chat list."""
        self.beginInsertRows(QModelIndex(), len(self._messages), len(self._messages))
        show_header = False
        if date_header:
            if not self._messages or self._messages[-1].get('dateHeader') != date_header:
                show_header = True
        self._messages.append({
            'msgId': msg_id,
            'sender': sender,
            'body': body,
            'timestamp': timestamp,
            'isMe': is_me,
            'status': status,
            'dateHeader': date_header,
            'showDateHeader': show_header,
            'isEncrypted': is_encrypted,
            'isEdited': is_edited
        })
        self.endInsertRows()

    def update_message_status(self, msg_id, status):
        """Update the status of a message with a specific database ID."""
        for idx, msg in enumerate(self._messages):
            if msg.get('msgId') == msg_id:
                msg['status'] = status
                self.dataChanged.emit(self.index(idx), self.index(idx), [self.StatusRole])
                return True
        return False

    def update_message_body(self, msg_id, new_body, is_edited=True):
        """Update the body of a message with a specific database ID."""
        for idx, msg in enumerate(self._messages):
            if msg.get('msgId') == msg_id:
                msg['body'] = new_body
                msg['isEdited'] = is_edited
                self.dataChanged.emit(self.index(idx), self.index(idx), [self.BodyRole, self.IsEditedRole])
                return True
        return False

    @Slot(result=dict)
    def getLastMyMessage(self):
        """Find the last message sent by the current user."""
        for idx in range(len(self._messages) - 1, -1, -1):
            msg = self._messages[idx]
            if msg.get('isMe'):
                return {
                    'msgId': msg.get('msgId'),
                    'body': msg.get('body'),
                    'index': idx
                }
        return {}

    def remove_message(self, row):
        """Remove a message at a specific row index."""
        if 0 <= row < len(self._messages):
            self.beginRemoveRows(QModelIndex(), row, row)
            self._messages.pop(row)
            self.endRemoveRows()
            return True
        return False

    def clear(self):
        self.beginResetModel()
        self._messages = []
        self.endResetModel()
