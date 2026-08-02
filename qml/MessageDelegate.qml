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
    property string resolvedImgSrc: root.isImg ? xmppBackend.getResolvedMediaUrl(model.body) : ""

    Connections {
        target: xmppBackend
        function onMediaUrlResolved(origUrl, resolvedUrl) {
            if (origUrl === model.body) {
                root.resolvedImgSrc = resolvedUrl;
            }
        }
    }

    function isImageLink(text) {
        if (!text)
            return false;
        var t = text.trim();
        if (t.indexOf(" ") !== -1)
            return false;
        if (t.match(/^aesgcm:\/\//i))
            return true;
        if (!t.match(/^(https?|file):\/\//i))
            return false;
        return !!t.match(/\.(png|jpg|jpeg|gif|webp|bmp)(\?.*)?(#.*)?$/i);
    }

    function isGifLink(text) {
        if (!text)
            return false;
        var t = text.trim();
        if (t.indexOf(" ") !== -1)
            return false;
        if (t.match(/^aesgcm:\/\/.*\.gif/i))
            return true;
        if (!t.match(/^(https?|file):\/\//i))
            return false;
        return !!t.match(/\.gif(\?.*)?(#.*)?$/i);
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

        width: root.isImg ? (root.isGif ? gifImage.width : staticImage.width) : (isSingleLine ? Math.max(dummyText.implicitWidth + property_timeW + 24, 75) : Math.min(property_maxW, Math.max(dummyText.implicitWidth + 24, textTimeRowMulti.implicitWidth + 28, 80)))

        height: root.isImg ? (root.isGif ? gifImage.height : staticImage.height) : (isSingleLine ? Math.max(messageTextSingle.implicitHeight, textTimeRowSingle.implicitHeight) + 14 : multiLineColumn.implicitHeight + 14)

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
                text: (model.formattedBody !== undefined && model.formattedBody !== "") ? model.formattedBody : model.body
                textFormat: Text.RichText
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

                Text {
                    text: model.timestamp
                    color: model.isMe ? window.msgOutText : window.colMuted
                    opacity: 0.7
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                }

                TintedIcon {
                    visible: (model.isEdited !== undefined && model.isEdited)
                    width: 10
                    height: 10
                    source: "icons/edit.svg"
                    color: model.isMe ? window.msgOutText : window.colMuted
                    opacity: 0.75
                    sourceSize: Qt.size(10, 10)
                    Layout.alignment: Qt.AlignVCenter
                }

                TintedIcon {
                    visible: (model.isEncrypted !== undefined && model.isEncrypted)
                    width: 8
                    height: 8
                    source: "icons/lock.svg"
                    color: model.isMe ? window.msgOutText : window.colMuted
                    opacity: 0.7
                    sourceSize: Qt.size(8, 8)
                    Layout.alignment: Qt.AlignVCenter
                }

                TintedIcon {
                    visible: model.isMe
                    width: 10
                    height: 10
                    source: {
                        var status = model.status;
                        if (status === "sending")
                            return "icons/hourglass.svg";
                        if (status === "read")
                            return "icons/done_all.svg";
                        if (status === "error")
                            return "icons/error.svg";
                        return "icons/check.svg";
                    }
                    color: {
                        var status = model.status;
                        if (status === "error")
                            return "#ef4444";
                        if (status === "sending")
                            return window.colMuted;
                        return model.isMe ? window.msgOutText : window.colPrimary;
                    }
                    opacity: 0.8
                    sourceSize: Qt.size(15, 15)
                    Layout.alignment: Qt.AlignVCenter
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
                text: (model.formattedBody !== undefined && model.formattedBody !== "") ? model.formattedBody : model.body
                textFormat: Text.RichText
                color: model.isMe ? window.msgOutText : window.msgInText
                font.pixelSize: 14
                wrapMode: Text.Wrap
            }

            RowLayout {
                id: textTimeRowMulti
                Layout.alignment: Qt.AlignRight
                spacing: 3

                Text {
                    text: model.timestamp
                    color: model.isMe ? window.msgOutText : window.colMuted
                    opacity: 0.7
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                }

                TintedIcon {
                    visible: (model.isEdited !== undefined && model.isEdited)
                    width: 10
                    height: 10
                    source: "icons/edit.svg"
                    color: model.isMe ? window.msgOutText : window.colMuted
                    opacity: 0.75
                    sourceSize: Qt.size(10, 10)
                    Layout.alignment: Qt.AlignVCenter
                }

                TintedIcon {
                    visible: (model.isEncrypted !== undefined && model.isEncrypted)
                    width: 8
                    height: 8
                    source: "icons/lock.svg"
                    color: model.isMe ? window.msgOutText : window.colMuted
                    opacity: 0.7
                    sourceSize: Qt.size(8, 8)
                    Layout.alignment: Qt.AlignVCenter
                }

                TintedIcon {
                    visible: model.isMe
                    width: 15
                    height: 15
                    source: {
                        var status = model.status;
                        if (status === "sending")
                            return "icons/hourglass.svg";
                        if (status === "read")
                            return "icons/done_all.svg";
                        if (status === "error")
                            return "icons/error.svg";
                        return "icons/check.svg";
                    }
                    color: {
                        var status = model.status;
                        if (status === "error")
                            return "#ef4444";
                        if (status === "sending")
                            return window.colMuted;
                        return model.isMe ? window.msgOutText : window.colPrimary;
                    }
                    opacity: 0.8
                    sourceSize: Qt.size(15, 15)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // --- Image / GIF Content ---
        Image {
            id: staticImage
            visible: root.isImg && !root.isGif
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: (root.isImg && !root.isGif) ? root.resolvedImgSrc : ""
            asynchronous: true

            width: Math.min(root.width * 0.6, 260)
            height: (sourceSize.width > 0 && sourceSize.height > 0) ? Math.min(260, Math.max(120, Math.round(width * sourceSize.height / sourceSize.width))) : 160

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
            source: (root.isImg && root.isGif) ? root.resolvedImgSrc : ""
            asynchronous: true

            width: Math.min(root.width * 0.6, 260)
            height: (sourceSize.width > 0 && sourceSize.height > 0) ? Math.min(260, Math.max(120, Math.round(width * sourceSize.height / sourceSize.width))) : 160

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

        // --- Semi-transparent Overlay Badge for Image Time, Read & OMEMO Status ---
        Rectangle {
            id: imageTimeBadge
            visible: root.isImg
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 6
            z: 10
            implicitWidth: imageTimeRow.implicitWidth + 14
            implicitHeight: 20
            radius: 10
            color: "#80111827"
            border.color: "#20ffffff"
            border.width: 1

            RowLayout {
                id: imageTimeRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: model.timestamp
                    color: "#ffffff"
                    font.pixelSize: 10
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                TintedIcon {
                    visible: (model.isEdited !== undefined && model.isEdited)
                    width: 9
                    height: 9
                    source: "icons/edit.svg"
                    color: "#ffffff"
                    opacity: 0.9
                    sourceSize: Qt.size(9, 9)
                    Layout.alignment: Qt.AlignVCenter
                }

                TintedIcon {
                    visible: (model.isEncrypted !== undefined && model.isEncrypted)
                    width: 8
                    height: 8
                    source: "icons/lock.svg"
                    color: "#ffffff"
                    opacity: 0.9
                    sourceSize: Qt.size(8, 8)
                    Layout.alignment: Qt.AlignVCenter
                }

                TintedIcon {
                    visible: model.isMe
                    width: 13
                    height: 13
                    source: {
                        var status = model.status;
                        if (status === "sending")
                            return "icons/hourglass.svg";
                        if (status === "read")
                            return "icons/done_all.svg";
                        if (status === "error")
                            return "icons/error.svg";
                        return "icons/check.svg";
                    }
                    color: {
                        var status = model.status;
                        if (status === "error")
                            return "#ef4444";
                        return "#ffffff";
                    }
                    opacity: 0.95
                    sourceSize: Qt.size(13, 13)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    messageContextMenu.popup();
                } else if (mouse.button === Qt.LeftButton && root.isImg) {
                    var view = ListView.view;
                    var p = root.parent;
                    while (p) {
                        if (p.objectName === "chatView") {
                            p.showImagePreview(root.resolvedImgSrc || model.body);
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
            id: saveImageItem
            visible: root.isImg
            text: "Save image as..."
            implicitWidth: 180
            implicitHeight: visible ? 36 : 0

            contentItem: Text {
                text: saveImageItem.text
                color: saveImageItem.hovered ? "white" : window.colText
                font.pixelSize: 14
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: saveImageItem.hovered ? window.colPrimary : "transparent"
                radius: 6
            }
            onTriggered: {
                xmppBackend.saveImageAs(messageContextMenu.messageBody);
            }
        }

        MenuItem {
            id: editItem
            visible: model.isMe && !root.isImg
            text: "Edit"
            implicitWidth: 180
            implicitHeight: visible ? 36 : 0

            contentItem: Text {
                text: editItem.text
                color: editItem.hovered ? "white" : window.colText
                font.pixelSize: 14
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: editItem.hovered ? window.colPrimary : "transparent"
                radius: 6
            }
            onTriggered: {
                var p = root.parent;
                while (p) {
                    if (p.objectName === "chatView") {
                        p.startEditingMessage(messageContextMenu.msgDatabaseId, messageContextMenu.messageBody, messageContextMenu.rowIndex);
                        break;
                    }
                    p = p.parent;
                }
            }
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
                xmppBackend.copyToClipboard(messageContextMenu.messageBody);
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
                xmppBackend.deleteMessage(messageContextMenu.msgDatabaseId, messageContextMenu.rowIndex);
            }
        }
    }
}
