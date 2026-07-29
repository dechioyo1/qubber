import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: parent ? parent.width : 500
    
    // Dynamic item height calculation
    height: (dateHeaderBadge.visible ? dateHeaderBadge.height + 16 : 0) + bubbleContainer.height + 6

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

    // Day & Month (Year) Header separator badge
    Rectangle {
        id: dateHeaderBadge
        visible: model.showDateHeader !== undefined && model.showDateHeader
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 6
        implicitWidth: dateHeaderText.implicitWidth + 24
        implicitHeight: 22
        radius: 11
        color: "#1e293b"
        border.color: window.colBorder
        border.width: 1

        Text {
            id: dateHeaderText
            anchors.centerIn: parent
            text: (model.dateHeader !== undefined && model.dateHeader !== null) ? model.dateHeader : ""
            color: window.colMuted
            font.pixelSize: 11
            font.bold: true
        }
    }

    // Main Bubble Container
    Item {
        id: bubbleContainer
        anchors.top: dateHeaderBadge.visible ? dateHeaderBadge.bottom : parent.top
        anchors.topMargin: dateHeaderBadge.visible ? 8 : 2
        anchors.left: model.isMe ? undefined : parent.left
        anchors.right: model.isMe ? parent.right : undefined
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        property real property_timeW: textTimeRowSingle.implicitWidth + 12
        property real property_maxW: Math.floor(root.width * 0.65)
        property bool isSingleLine: !root.isImg && ((dummyText.implicitWidth + property_timeW) <= (property_maxW - 24))

        width: root.isImg
            ? (root.isGif ? gifImage.width : staticImage.width)
            : (isSingleLine
                ? Math.max(dummyText.implicitWidth + property_timeW + 24, 75)
                : Math.min(property_maxW, Math.max(dummyText.implicitWidth + 24, textTimeRowMulti.implicitWidth + 28, 80)))

        height: root.isImg
            ? (root.isGif ? gifImage.height : staticImage.height)
            : (isSingleLine
                ? Math.max(messageTextSingle.implicitHeight, textTimeRowSingle.implicitHeight) + 14
                : multiLineColumn.implicitHeight + 14)

        // Bubble Background Rectangle
        Rectangle {
            id: bubbleRect
            anchors.fill: parent
            radius: 16
            clip: true
            
            color: model.isMe ? window.msgOutBg : window.msgInBg
            border.color: model.isMe ? "transparent" : window.colBorder
            border.width: model.isMe ? 0 : 1
        }

        // --- Single Line Layout (Text + Time side-by-side like Telegram screenshot 1) ---
        RowLayout {
            id: singleLineRow
            visible: !root.isImg && bubbleContainer.isSingleLine
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 8

            Text {
                id: messageTextSingle
                text: model.body
                color: model.isMe ? window.msgOutText : window.msgInText
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                id: textTimeRowSingle
                Layout.alignment: Qt.AlignBottom
                spacing: 3

                Image {
                    visible: (model.isEncrypted !== undefined && model.isEncrypted)
                    width: 12
                    height: 12
                    source: model.isMe ? "icons/lock_white.svg" : "icons/lock_muted.svg"
                    sourceSize: Qt.size(12, 12)
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: model.timestamp
                    color: model.isMe ? window.colMuted : window.colMuted
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                }

                Image {
                    visible: model.isMe
                    width: 18
                    height: 18
                    source: {
                        var status = model.status;
                        if (status === "sending") return "icons/hourglass_muted.svg";
                        if (status === "sent") return "icons/check_primary.svg";
                        if (status === "read") return "icons/done_all_primary.svg";
                        if (status === "error") return "icons/error_red.svg";
                        return "icons/check_primary.svg";
                    }
                    sourceSize: Qt.size(18, 18)
                }
            }
        }

        // --- Multi Line Layout (Text wrapped + Time at bottom-right like Telegram screenshot 2) ---
        ColumnLayout {
            id: multiLineColumn
            visible: !root.isImg && !bubbleContainer.isSingleLine
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            anchors.topMargin: 7
            spacing: 2

            Text {
                id: messageTextMulti
                Layout.fillWidth: true
                text: model.body
                color: model.isMe ? window.msgOutText : window.msgInText
                font.pixelSize: 14
                wrapMode: Text.Wrap
            }

            RowLayout {
                id: textTimeRowMulti
                Layout.alignment: Qt.AlignRight
                spacing: 3

                Image {
                    visible: (model.isEncrypted !== undefined && model.isEncrypted)
                    width: 12
                    height: 12
                    source: model.isMe ? "icons/lock_white.svg" : "icons/lock_muted.svg"
                    sourceSize: Qt.size(12, 12)
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: model.timestamp
                    color: model.isMe ? "#ffffffa0" : window.colMuted
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                }

                Image {
                    visible: model.isMe
                    width: 14
                    height: 14
                    source: {
                        var status = model.status;
                        if (status === "sending") return "icons/hourglass_muted.svg";
                        if (status === "sent") return "icons/check_primary.svg";
                        if (status === "read") return "icons/done_all_primary.svg";
                        if (status === "error") return "icons/error_red.svg";
                        return "icons/check_primary.svg";
                    }
                    sourceSize: Qt.size(14, 14)
                }
            }
        }

        // --- Image / GIF Content ---
        Image {
            id: staticImage
            visible: root.isImg && !root.isGif
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: (root.isImg && !root.isGif) ? model.body : ""
            asynchronous: true
            
            width: Math.min(root.width * 0.6, 260)
            height: (sourceSize.width > 0 && sourceSize.height > 0)
                ? Math.min(260, Math.max(120, Math.round(width * sourceSize.height / sourceSize.width)))
                : 160
            
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
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: (root.isImg && root.isGif) ? model.body : ""
            asynchronous: true
            
            width: Math.min(root.width * 0.6, 260)
            height: (sourceSize.width > 0 && sourceSize.height > 0)
                ? Math.min(260, Math.max(120, Math.round(width * sourceSize.height / sourceSize.width)))
                : 160
            
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

        // --- Semi-transparent Overlay Badge for Image Time & Read Status ---
        Rectangle {
            id: imageTimeBadge
            visible: root.isImg
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 6
            implicitWidth: imageTimeRow.implicitWidth + 12
            implicitHeight: 20
            radius: 10
            color: "#00000080"

            RowLayout {
                id: imageTimeRow
                anchors.centerIn: parent
                spacing: 3

                Image {
                    visible: (model.isEncrypted !== undefined && model.isEncrypted)
                    width: 11
                    height: 11
                    source: "icons/lock_white.svg"
                    sourceSize: Qt.size(11, 11)
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: model.timestamp
                    color: "white"
                    font.pixelSize: 10
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Image {
                    visible: model.isMe
                    width: 13
                    height: 13
                    source: {
                        var status = model.status;
                        if (status === "sending") return "icons/hourglass_white.svg";
                        if (status === "sent") return "icons/check_white.svg";
                        if (status === "read") return "icons/done_all_white.svg";
                        if (status === "error") return "icons/error_white.svg";
                        return "icons/check_white.svg";
                    }
                    sourceSize: Qt.size(13, 13)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    messageContextMenu.popup()
                } else if (mouse.button === Qt.LeftButton && root.isImg) {
                    var view = ListView.view;
                    var p = root.parent;
                    while (p) {
                        if (p.objectName === "chatView") {
                            p.showImagePreview(model.body);
                            break;
                        }
                        p = p.parent;
                    }
                }
            }
        }
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
