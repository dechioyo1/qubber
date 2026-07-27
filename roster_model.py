from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Slot

class RosterModel(QAbstractListModel):
    JidRole = Qt.ItemDataRole.UserRole + 1
    NameRole = Qt.ItemDataRole.UserRole + 2
    StatusRole = Qt.ItemDataRole.UserRole + 3
    StatusMessageRole = Qt.ItemDataRole.UserRole + 4
    UnreadCountRole = Qt.ItemDataRole.UserRole + 5

    def __init__(self, parent=None):
        super().__init__(parent)
        self._contacts = []  # list of dicts: {'jid': ..., 'name': ..., 'status': ..., 'statusMessage': ..., 'unreadCount': ...}

    def roleNames(self):
        return {
            self.JidRole: b"jid",
            self.NameRole: b"name",
            self.StatusRole: b"status",
            self.StatusMessageRole: b"statusMessage",
            self.UnreadCountRole: b"unreadCount"
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
        return None

    def set_contacts(self, contacts):
        """Reset contact list with new items and sort online first."""
        self.beginResetModel()
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

    def add_contact(self, jid, name=None, status='offline', statusMessage='', unreadCount=0):
        """Add a contact if not already present."""
        for contact in self._contacts:
            if contact['jid'] == jid:
                # Update if already exists
                self.update_contact(jid, name=name, status=status, statusMessage=statusMessage)
                return
        
        self.beginInsertRows(QModelIndex(), len(self._contacts), len(self._contacts))
        self._contacts.append({
            'jid': jid,
            'name': name or jid.split('@')[0],
            'status': status,
            'statusMessage': statusMessage,
            'unreadCount': unreadCount
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
