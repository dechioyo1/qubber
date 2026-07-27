import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: delegate
    width: parent ? parent.width : 280
    
    // Dynamic search filtering
    visible: {
        var ft = ListView.view.filterText;
        if (!ft) return true;
        return model.name.toLowerCase().indexOf(ft) !== -1 || model.jid.toLowerCase().indexOf(ft) !== -1;
    }
    
    height: visible ? 68 : 0
    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
    Behavior on opacity { NumberAnimation { duration: 150 } }
    opacity: visible ? 1.0 : 0.0

    // Check if this contact is the active chat
    property bool isActive: model.jid === xmppBackend.activeChatJid
    
    background: Rectangle {
        color: delegate.isActive 
            ? "#6366f122" // Semi-transparent indigo
            : (delegate.hovered ? "#1e293b70" : "transparent")
            
        // Left accent indicator for selected contact
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            color: window.colPrimary
            visible: delegate.isActive
            radius: 2
        }
        
        radius: 12
        border.color: delegate.isActive ? "#6366f144" : "transparent"
        border.width: 1
        
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    
    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12
        visible: delegate.visible // Prevent child rendering when filtered out
        
        // Presence avatar container
        Item {
            width: 42
            height: 42
            Layout.alignment: Qt.AlignVCenter
            
            // Avatar circle background
            Rectangle {
                anchors.fill: parent
                radius: 21
                color: "#334155"
                
                Text {
                    anchors.centerIn: parent
                    text: model.name.substring(0, 1).toUpperCase()
                    color: window.colText
                    font.pixelSize: 16
                    font.bold: true
                }
            }
            
            // Presence status dot
            Rectangle {
                width: 12
                height: 12
                radius: 6
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                border.color: "#0f172a"
                border.width: 2
                
                color: {
                    var status = model.status;
                    if (status === "available" || status === "chat") return window.colOnline;
                    if (status === "away" || status === "xa") return window.colAway;
                    if (status === "dnd") return window.colDnd;
                    return window.colOffline;
                }
            }
        }
        
        // Name, JID, and Status Message
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            
            Text {
                text: model.name
                color: window.colText
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            Text {
                text: model.statusMessage !== "" ? model.statusMessage : model.jid
                color: window.colMuted
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
        
        // Unread Badge
        Rectangle {
            visible: model.unreadCount > 0
            width: Math.max(20, unreadText.implicitWidth + 8)
            height: 20
            radius: 10
            color: "#ec4899"
            Layout.alignment: Qt.AlignVCenter
            
            Text {
                id: unreadText
                anchors.centerIn: parent
                text: model.unreadCount
                color: "white"
                font.pixelSize: 11
                font.bold: true
            }
        }
    }
    
    onClicked: {
        xmppBackend.selectChat(model.jid)
        var p = delegate.parent;
        while (p) {
            if (p.objectName === "contactsListPopup") {
                p.close();
                break;
            }
            p = p.parent;
        }
    }
}
