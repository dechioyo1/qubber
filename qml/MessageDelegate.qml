import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: parent ? parent.width : 500
    height: bubbleColumn.implicitHeight + 10

    ColumnLayout {
        id: bubbleColumn
        anchors.left: model.isMe ? undefined : parent.left
        anchors.right: model.isMe ? parent.right : undefined
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        
        // Dynamically compute width up to 70% of the screen width
        width: Math.min(root.width * 0.7, Math.max(messageText.implicitWidth + 24, 60))
        spacing: 3

        Rectangle {
            id: bubbleRect
            Layout.fillWidth: true
            implicitHeight: messageText.implicitHeight + 16
            radius: 14
            
            color: model.isMe ? "transparent" : window.colCard
            border.color: model.isMe ? "transparent" : window.colBorder
            border.width: model.isMe ? 0 : 1
            
            gradient: model.isMe ? meGradient : null

            Text {
                id: messageText
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                text: model.body
                color: window.colText
                font.pixelSize: 14
                wrapMode: Text.Wrap
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        messageContextMenu.popup()
                    }
                }
            }
        }

        Text {
            text: model.timestamp
            color: window.colMuted
            font.pixelSize: 10
            Layout.alignment: model.isMe ? Qt.AlignRight : Qt.AlignLeft
            rightPadding: 6
            leftPadding: 6
        }
    }

    Gradient {
        id: meGradient
        GradientStop { position: 0.0; color: window.colPrimary }
        GradientStop { position: 1.0; color: window.colAccent }
    }

    Menu {
        id: messageContextMenu
        property string messageBody: model.body
        property int msgDatabaseId: model.msgId
        property int rowIndex: index
        
        padding: 6
        
        background: Rectangle {
            implicitWidth: 172
            color: "#1e293b"
            border.color: window.colBorder
            radius: 8
        }
        
        MenuItem {
            id: copyItem
            text: "Copy text"
            implicitWidth: 160
            implicitHeight: 32
            
            contentItem: Text {
                text: copyItem.text
                color: copyItem.hovered ? "white" : window.colText
                font.pixelSize: 12
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: copyItem.hovered ? window.colPrimary : "transparent"
                radius: 6
            }
            onTriggered: {
                xmppBackend.copyToClipboard(messageContextMenu.messageBody)
            }
        }
        
        MenuItem {
            id: deleteItem
            text: "Delete message for me"
            implicitWidth: 160
            implicitHeight: 32
            
            contentItem: Text {
                text: deleteItem.text
                color: deleteItem.hovered ? "#ef4444" : window.colText
                font.pixelSize: 12
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: deleteItem.hovered ? "#dc262615" : "transparent"
                radius: 6
            }
            onTriggered: {
                xmppBackend.deleteMessage(messageContextMenu.msgDatabaseId, messageContextMenu.rowIndex)
            }
        }
    }
}
