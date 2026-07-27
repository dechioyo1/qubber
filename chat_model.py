from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt

class ChatModel(QAbstractListModel):
    SenderRole = Qt.ItemDataRole.UserRole + 1
    BodyRole = Qt.ItemDataRole.UserRole + 2
    TimestampRole = Qt.ItemDataRole.UserRole + 3
    IsMeRole = Qt.ItemDataRole.UserRole + 4
    MsgIdRole = Qt.ItemDataRole.UserRole + 5

    def __init__(self, parent=None):
        super().__init__(parent)
        self._messages = []  # list of dicts: {'sender': ..., 'body': ..., 'timestamp': ..., 'isMe': ...}

    def roleNames(self):
        return {
            self.SenderRole: b"sender",
            self.BodyRole: b"body",
            self.TimestampRole: b"timestamp",
            self.IsMeRole: b"isMe",
            self.MsgIdRole: b"msgId"
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
        return None

    def set_messages(self, messages):
        """Set the entire message list for the current active chat."""
        self.beginResetModel()
        self._messages = list(messages)
        self.endResetModel()

    def add_message(self, sender, body, timestamp, is_me, msg_id=None):
        """Append a single message to the active chat list."""
        self.beginInsertRows(QModelIndex(), len(self._messages), len(self._messages))
        self._messages.append({
            'msgId': msg_id,
            'sender': sender,
            'body': body,
            'timestamp': timestamp,
            'isMe': is_me
        })
        self.endInsertRows()

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
