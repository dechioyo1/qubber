from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Slot

class RosterModel(QAbstractListModel):
    JidRole = Qt.ItemDataRole.UserRole + 1
    NameRole = Qt.ItemDataRole.UserRole + 2
    StatusRole = Qt.ItemDataRole.UserRole + 3
    StatusMessageRole = Qt.ItemDataRole.UserRole + 4
    UnreadCountRole = Qt.ItemDataRole.UserRole + 5
    LastMessageRole = Qt.ItemDataRole.UserRole + 6
    LastMessageTimeRole = Qt.ItemDataRole.UserRole + 7
    LastMessageIsMeRole = Qt.ItemDataRole.UserRole + 8
    LastMessageStatusRole = Qt.ItemDataRole.UserRole + 9
    AvatarRole = Qt.ItemDataRole.UserRole + 10
    LastSeenRole = Qt.ItemDataRole.UserRole + 11

    def __init__(self, parent=None):
        super().__init__(parent)
        self._contacts = []  # list of dicts

    def roleNames(self):
        return {
            self.JidRole: b"jid",
            self.NameRole: b"name",
            self.StatusRole: b"status",
            self.StatusMessageRole: b"statusMessage",
            self.UnreadCountRole: b"unreadCount",
            self.LastMessageRole: b"lastMessage",
            self.LastMessageTimeRole: b"lastMessageTime",
            self.LastMessageIsMeRole: b"lastMessageIsMe",
            self.LastMessageStatusRole: b"lastMessageStatus",
            self.AvatarRole: b"avatar",
            self.LastSeenRole: b"lastSeen"
        }

    def rowCount(self, parent=QModelIndex()):
        if parent.isValid():
            return 0
        return len(self._contacts)

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._contacts)):
            return None
        
        contact = self._contacts[index.row()]
        if role == self.JidRole:
            return contact['jid']
        elif role == self.NameRole:
            return contact['name'] or contact['jid']
        elif role == self.StatusRole:
            return contact['status']
        elif role == self.StatusMessageRole:
            return contact['statusMessage']
        elif role == self.UnreadCountRole:
            return contact['unreadCount']
        elif role == self.LastMessageRole:
            return contact.get('lastMessage', '')
        elif role == self.LastMessageTimeRole:
            return contact.get('lastMessageTime', '')
        elif role == self.LastMessageIsMeRole:
            return contact.get('lastMessageIsMe', False)
        elif role == self.LastMessageStatusRole:
            return contact.get('lastMessageStatus', 'sent')
        elif role == self.AvatarRole:
            return contact.get('avatar', '')
        elif role == self.LastSeenRole:
            return contact.get('lastSeen', '')
        return None

    def set_contacts(self, contacts, sort_by_latest=False):
        """Reset contact list with new items."""
        self.beginResetModel()
        if sort_by_latest:
            self._contacts = sorted(
                contacts,
                key=lambda c: c.get('lastMsgId', 0),
                reverse=True
            )
        else:
            self._contacts = sorted(
                contacts, 
                key=lambda c: (c.get('status', 'offline') == 'offline', (c.get('name') or c.get('jid', '')).lower())
            )
        self.endResetModel()

    def update_contact(self, jid, **kwargs):
        """Update properties of an existing contact, or add them if they don't exist."""
        for idx, contact in enumerate(self._contacts):
            if contact['jid'] == jid:
                for k, v in kwargs.items():
                    contact[k] = v
                self.dataChanged.emit(self.index(idx), self.index(idx), list(self.roleNames().keys()))
                return
        # If not found, add it
        self.add_contact(jid, **kwargs)

    def add_contact(self, jid, name=None, status='offline', statusMessage='', unreadCount=0, lastMessage='', lastMessageTime='', lastMessageIsMe=False, lastMessageStatus='sent', avatar='', lastSeen=''):
        """Add a contact if not already present."""
        for contact in self._contacts:
            if contact['jid'] == jid:
                # Update if already exists
                self.update_contact(jid, name=name, status=status, statusMessage=statusMessage, lastMessage=lastMessage, lastMessageTime=lastMessageTime, lastMessageIsMe=lastMessageIsMe, lastMessageStatus=lastMessageStatus, avatar=avatar, lastSeen=lastSeen)
                return
        
        self.beginInsertRows(QModelIndex(), len(self._contacts), len(self._contacts))
        self._contacts.append({
            'jid': jid,
            'name': name or jid.split('@')[0],
            'status': status,
            'statusMessage': statusMessage,
            'unreadCount': unreadCount,
            'lastMessage': lastMessage,
            'lastMessageTime': lastMessageTime,
            'lastMessageIsMe': lastMessageIsMe,
            'lastMessageStatus': lastMessageStatus,
            'avatar': avatar,
            'lastSeen': lastSeen
        })
        self.endInsertRows()

    @Slot(str, result=bool)
    def hasContact(self, jid):
        for contact in self._contacts:
            if contact['jid'] == jid:
                return True
        return False

    @Slot(str)
    def clearUnread(self, jid):
        self.update_contact(jid, unreadCount=0)

    @Slot()
    def clear(self):
        self.beginResetModel()
        self._contacts = []
        self.endResetModel()
