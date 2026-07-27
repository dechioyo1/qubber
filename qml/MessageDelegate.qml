import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: parent ? parent.width : 500
    height: bubbleColumn.implicitHeight + 10

    property bool isImg: isImageLink(model.body)
    property bool isGif: isGifLink(model.body)

    function isImageLink(text) {
        if (!text) return false;
        var t = text.trim();
        if (t.indexOf(" ") !== -1) return false;
        if (!t.match(/^https?:\/\//i)) return false;
        return !!t.match(/\.(png|jpg|jpeg|gif|webp|bmp)(\?.*)?$/i);
    }
    
    function isGifLink(text) {
        if (!text) return false;
        var t = text.trim();
        if (t.indexOf(" ") !== -1) return false;
        if (!t.match(/^https?:\/\//i)) return false;
        return !!t.match(/\.gif(\?.*)?$/i);
    }

    Text {
        id: dummyText
        text: model.body
        font.pixelSize: 14
        visible: false
    }

    ColumnLayout {
        id: bubbleColumn
        anchors.left: model.isMe ? undefined : parent.left
        anchors.right: model.isMe ? parent.right : undefined
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        
        // Dynamically compute width using unwrapped dummyText implicitWidth
        width: root.isImg
            ? (root.isGif ? gifImage.width : staticImage.width) + 24
            : Math.min(root.width * 0.6, Math.max(dummyText.implicitWidth + 24, 60))
        spacing: 3

        Rectangle {
            id: bubbleRect
            Layout.fillWidth: true
            implicitHeight: root.isImg
                ? (root.isGif ? gifImage.height : staticImage.height) + 16
                : messageText.implicitHeight + 16
            radius: 14
            
            color: model.isMe ? window.msgOutBg : window.msgInBg
            border.color: model.isMe ? "transparent" : window.colBorder
            border.width: model.isMe ? 0 : 1
 
            Text {
                id: messageText
                visible: !root.isImg
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                text: model.body
                color: model.isMe ? window.msgOutText : window.msgInText
                font.pixelSize: 14
                wrapMode: (dummyText.implicitWidth + 24 > root.width * 0.6) ? Text.Wrap : Text.WordWrap
            }

            Image {
                id: staticImage
                visible: root.isImg && !root.isGif
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                source: (root.isImg && !root.isGif) ? model.body : ""
                asynchronous: true
                
                width: sourceSize.width > 0 ? Math.min(220, sourceSize.width) : 120
                height: sourceSize.width > 0 ? (width * sourceSize.height / sourceSize.width) : 120
                
                Rectangle {
                    anchors.fill: parent
                    color: "#00000040"
                    visible: staticImage.status === Image.Loading
                    
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: parent.visible
                    }
                }
            }

            AnimatedImage {
                id: gifImage
                visible: root.isImg && root.isGif
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                source: (root.isImg && root.isGif) ? model.body : ""
                asynchronous: true
                
                width: sourceSize.width > 0 ? Math.min(220, sourceSize.width) : 120
                height: sourceSize.width > 0 ? (width * sourceSize.height / sourceSize.width) : 120
                
                Rectangle {
                    anchors.fill: parent
                    color: "#00000040"
                    visible: gifImage.status === AnimatedImage.Loading
                    
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: parent.visible
                    }
                }
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

        RowLayout {
            Layout.alignment: model.isMe ? Qt.AlignRight : Qt.AlignLeft
            spacing: 4
            Layout.rightMargin: 6
            Layout.leftMargin: 6
            
            Text {
                text: model.timestamp
                color: window.colMuted
                font.pixelSize: 10
                verticalAlignment: Text.AlignVCenter
            }
            
            Image {
                visible: model.isMe
                width: 13
                height: 13
                source: {
                    var status = model.status;
                    if (status === "sending") return "icons/hourglass_muted.svg";
                    if (status === "sent") return "icons/check_muted.svg";
                    if (status === "read") return "icons/done_all_primary.svg";
                    if (status === "error") return "icons/error_red.svg";
                    return "icons/check_muted.svg";
                }
                sourceSize: Qt.size(13, 13)
            }
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
            implicitWidth: 192
            color: window.colCard
            border.color: window.colBorder
            radius: 8
        }
        
        MenuItem {
            id: copyItem
            text: "Copy text"
            implicitWidth: 180
            implicitHeight: 36
            
            contentItem: Text {
                text: copyItem.text
                color: copyItem.hovered ? "white" : window.colText
                font.pixelSize: 14
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
            implicitWidth: 180
            implicitHeight: 36
            
            contentItem: Text {
                text: deleteItem.text
                color: deleteItem.hovered ? "#ef4444" : window.colText
                font.pixelSize: 14
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
