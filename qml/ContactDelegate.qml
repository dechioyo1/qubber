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
    
    function getAvatarGradient(nameStr) {
        var colors = [
            ["#ff845e", "#d45246"], // Red / Orange
            ["#9ad164", "#46ba43"], // Green
            ["#e5ca77", "#d09306"], // Yellow / Gold
            ["#518ffa", "#366ecf"], // Blue
            ["#b694f9", "#6c61df"], // Purple
            ["#ff8aac", "#d95574"], // Pink
            ["#52b3e4", "#2c7dd4"], // Cyan
            ["#febb5b", "#f68136"]  // Deep Orange
        ];
        if (!nameStr) return colors[0];
        var hash = 0;
        for (var i = 0; i < nameStr.length; i++) {
            hash = nameStr.charCodeAt(i) + ((hash << 5) - hash);
        }
        var idx = Math.abs(hash) % colors.length;
        return colors[idx];
    }
    
    background: Rectangle {
        color: delegate.isActive 
            ? window.sidebarBgActive
            : (delegate.hovered ? window.sidebarBgOver : "transparent")
            
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
        
        radius: 0
        border.color: delegate.isActive ? '#e41f84f9' : "transparent"
        border.width: 1
    }
    
    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12
        visible: delegate.visible // Prevent child rendering when filtered out
        
        // Presence avatar container
        Item {
            width: 48
            height: 48
            Layout.alignment: Qt.AlignVCenter
            
            // Avatar square background with 2px radius and colorful gradient / cached avatar image
            Rectangle {
                anchors.fill: parent
                radius: 2
                clip: true
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: getAvatarGradient(model.name || model.jid)[0] }
                    GradientStop { position: 1.0; color: getAvatarGradient(model.name || model.jid)[1] }
                }
                
                Text {
                    anchors.centerIn: parent
                    visible: avatarImg.status !== Image.Ready
                    text: (model.name && model.name.length > 0) ? model.name.substring(0, 1).toUpperCase() : "?"
                    color: "white"
                    font.pixelSize: 22
                    font.bold: true
                }

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: (model.avatar !== undefined && model.avatar !== null) ? model.avatar : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
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
        
        // Name, JID, and Last Message / Status / Last Seen
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: model.name
                    color: delegate.isActive ? "white" : window.colText
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                Text {
                    text: (model.lastMessageTime !== undefined && model.lastMessageTime !== null) ? model.lastMessageTime : ""
                    color: delegate.isActive ? "#ffffffc0" : window.colMuted
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: (model.isTyping !== undefined && model.isTyping)
                        ? "typing..."
                        : ((model.lastMessage && model.lastMessage !== "") 
                            ? model.lastMessage 
                            : ((model.lastSeen && model.lastSeen !== "") 
                                ? model.lastSeen 
                                : (model.statusMessage !== "" ? model.statusMessage : model.jid)))
                    color: (model.isTyping !== undefined && model.isTyping)
                        ? window.colAccent
                        : (delegate.isActive ? "#ffffffe0" : window.colMuted)
                    font.pixelSize: 14
                    font.italic: model.isTyping !== undefined && model.isTyping
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                TintedIcon {
                    visible: (model.isTyping === undefined || !model.isTyping) && model.lastMessageIsMe !== undefined && model.lastMessageIsMe && model.lastMessage && model.lastMessage !== ""
                    width: 14
                    height: 14
                    source: {
                        var status = model.lastMessageStatus;
                        if (status === "sending") return "icons/hourglass.svg";
                        if (status === "sent") return "icons/check.svg";
                        if (status === "read") return "icons/done_all.svg";
                        if (status === "error") return "icons/error.svg";
                        return "icons/check.svg";
                    }
                    color: {
                        var status = model.lastMessageStatus;
                        if (status === "error") return "#ef4444";
                        if (delegate.isActive) return "#ffffff";
                        if (status === "read") return window.colPrimary;
                        return window.colMuted;
                    }
                    sourceSize: Qt.size(14, 14)
                }
                
                // Unread Badge (placed on the level of last message)
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
