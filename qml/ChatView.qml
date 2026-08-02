import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    objectName: "chatView"

    property string selfStatus: "available"
    property string hoveredStatus: ""
    property string filterText: searchInput.text.toLowerCase().trim()
    property bool sidebarCollapsed: false
    property bool showRightSidebar: false

    property int editingMsgId: 0
    property string editingMsgText: ""
    property int editingRowIndex: -1

    Connections {
        target: xmppBackend
        function onActiveChatJidChanged(jid) {
            root.cancelEditing();
        }
    }

    function startEditingMessage(msgId, text, rowIndex) {
        root.editingMsgId = msgId;
        root.editingMsgText = text;
        root.editingRowIndex = rowIndex !== undefined ? rowIndex : -1;
        messageInput.text = text;
        messageInput.forceActiveFocus();
        messageInput.cursorPosition = text.length;
    }

    function cancelEditing() {
        root.editingMsgId = 0;
        root.editingMsgText = "";
        root.editingRowIndex = -1;
        messageInput.text = "";
    }

    function scrollToEditingMessage() {
        if (root.editingRowIndex >= 0) {
            chatHistoryView.positionViewAtIndex(root.editingRowIndex, ListView.Center);
        }
    }

    function confirmSendFile(url) {
        if (!url || !xmppBackend || xmppBackend.activeChatJid === "")
            return;
        sendFileConfirmDialog.fileUrl = url;
        sendFileConfirmDialog.fileSize = xmppBackend.getFormattedFileSize(url);
        sendFileConfirmDialog.captionText = "";
        sendFileConfirmDialog.open();
    }

    function showImagePreview(url) {
        imagePreviewDialog.imageSource = url;
        imagePreviewDialog.open();
    }

    function getHeaderAvatarGradient(nameStr) {
        var colors = [["#ff845e", "#d45246"], ["#9ad164", "#46ba43"], ["#e5ca77", "#d09306"], ["#518ffa", "#366ecf"], ["#b694f9", "#6c61df"], ["#ff8aac", "#d95574"], ["#52b3e4", "#2c7dd4"], ["#febb5b", "#f68136"]];
        if (!nameStr)
            return colors[0];
        var hash = 0;
        for (var i = 0; i < nameStr.length; i++) {
            hash = nameStr.charCodeAt(i) + ((hash << 5) - hash);
        }
        var idx = Math.abs(hash) % colors.length;
        return colors[idx];
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        handle: Rectangle {
            implicitWidth: 1
            color: window.colBorder
        }

        // Sidebar (Contacts & Settings)
        Rectangle {
            id: sidebar
            visible: !root.sidebarCollapsed
            SplitView.preferredWidth: 240
            SplitView.minimumWidth: 200
            SplitView.maximumWidth: 300
            color: window.sidebarBg

            // Border divider
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: window.colBorder
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Search Input Field & Collapse Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 56
                    color: window.sidebarHeaderBg

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: window.colBorder
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            placeholderText: "Search..."
                            placeholderTextColor: "#4b5563"
                            color: window.colText
                            font.pixelSize: 13
                            selectByMouse: true
                            leftPadding: 32
                            rightPadding: 10
                            verticalAlignment: Text.AlignVCenter

                            background: Rectangle {
                                color: searchInput.activeFocus ? "#0b0f19" : window.colInputBg
                                border.color: searchInput.activeFocus ? window.colPrimary : window.colBorder
                                border.width: 1
                                radius: 8
                            }

                            Image {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                source: "icons/search_muted.svg"
                                sourceSize: Qt.size(16, 16)
                                opacity: 0.6
                            }
                        }

                        Button {
                            id: collapseSidebarBtn
                            visible: xmppBackend ? xmppBackend.activeChatJid !== "" : false
                            implicitWidth: 32
                            implicitHeight: 32

                            contentItem: Image {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: collapseSidebarBtn.hovered ? "icons/chevron_left_white.svg" : "icons/chevron_left_muted.svg"
                                sourceSize: Qt.size(20, 20)
                            }

                            background: Rectangle {
                                color: collapseSidebarBtn.hovered ? "#33415520" : "transparent"
                                radius: 16
                            }

                            onClicked: {
                                root.sidebarCollapsed = true;
                            }
                        }
                    }
                }

                // Contacts List View
                ListView {
                    id: rosterList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: chatsListModel
                    interactive: false

                    // Expose filterText to delegates
                    property string filterText: root.filterText

                    delegate: ContactDelegate {}

                    // Spacer at the bottom
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    // Speed up wheel scrolling using a pass-through MouseArea
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: wheel => {
                            if (rosterList.contentHeight > rosterList.height && wheel.angleDelta.y !== 0) {
                                var newY = rosterList.contentY - wheel.angleDelta.y * 0.6;
                                rosterList.contentY = Math.max(rosterList.originY, Math.min(newY, rosterList.contentHeight - rosterList.height));
                                wheel.accepted = true;
                            }
                        }
                    }
                }
            }
        }

        // Chat Area (Selected Chat Details & Log)
        Rectangle {
            SplitView.fillWidth: true
            color: "transparent"

            // Empty State (No Active Chat)
            ColumnLayout {
                anchors.centerIn: parent
                visible: xmppBackend ? xmppBackend.activeChatJid === "" : true
                spacing: 16

                Rectangle {
                    width: 80
                    height: 80
                    radius: 40
                    color: "#1e293b"
                    Layout.alignment: Qt.AlignHCenter

                    Image {
                        anchors.centerIn: parent
                        width: 36
                        height: 36
                        source: "icons/chat_muted.svg"
                        sourceSize: Qt.size(36, 36)
                    }
                }

                Text {
                    text: "No Conversation Active"
                    color: window.colText
                    font.pixelSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Select a contact from the roster list to start messaging."
                    color: window.colMuted
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Active Chat Interface Container
            Item {
                anchors.fill: parent
                visible: xmppBackend ? xmppBackend.activeChatJid !== "" : false

                ColumnLayout {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: (root.showRightSidebar && (xmppBackend ? xmppBackend.activeChatJid !== "" : false)) ? 320 : 0
                    Behavior on anchors.rightMargin {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                    spacing: 0

                    // Active Contact Header
                    Rectangle {
                        Layout.fillWidth: true
                        height: 56
                        color: "#11132240"

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: window.colBorder
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 12

                            Button {
                                id: expandSidebarBtn
                                visible: root.sidebarCollapsed
                                implicitWidth: 32
                                implicitHeight: 32

                                contentItem: Image {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    source: expandSidebarBtn.hovered ? "icons/menu_white.svg" : "icons/menu_muted.svg"
                                    sourceSize: Qt.size(20, 20)
                                }

                                background: Rectangle {
                                    color: expandSidebarBtn.hovered ? "#33415520" : "transparent"
                                    radius: 16
                                }

                                onClicked: {
                                    root.sidebarCollapsed = false;
                                }
                            }

                            // Active Contact Avatar
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 4
                                clip: true
                                Layout.alignment: Qt.AlignVCenter

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: root.getHeaderAvatarGradient(xmppBackend ? xmppBackend.activeChatJid : "")[0]
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: root.getHeaderAvatarGradient(xmppBackend ? xmppBackend.activeChatJid : "")[1]
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: headerAvatarImg.status !== Image.Ready
                                    text: (xmppBackend && xmppBackend.activeChatJid) ? xmppBackend.activeChatJid.substring(0, 1).toUpperCase() : "?"
                                    color: "white"
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Image {
                                    id: headerAvatarImg
                                    anchors.fill: parent
                                    source: xmppBackend ? xmppBackend.activeChatAvatar : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                }
                            }

                            // Contact JID / Name & Last Seen
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 1

                                Text {
                                    text: xmppBackend ? xmppBackend.activeChatJid : ""
                                    color: window.colText
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: xmppBackend ? xmppBackend.activeChatLastSeen : ""
                                    color: (xmppBackend && xmppBackend.activeChatLastSeen === "typing...") ? window.colAccent : window.colMuted
                                    font.pixelSize: 11
                                    font.italic: xmppBackend ? (xmppBackend.activeChatLastSeen === "typing...") : false
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            RowLayout {
                                spacing: 4
                                Layout.alignment: Qt.AlignVCenter

                                Button {
                                    id: lockIconBtn
                                    implicitWidth: 32
                                    implicitHeight: 32

                                    contentItem: TintedIcon {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        source: {
                                            var isOmemo = (xmppBackend && xmppBackend.activeChatEncryptionMode === "OMEMO");
                                            return isOmemo ? "icons/lock.svg" : "icons/lock_open_right.svg";
                                        }
                                        color: {
                                            var isOmemo = (xmppBackend && xmppBackend.activeChatEncryptionMode === "OMEMO");
                                            if (isOmemo)
                                                return window.colAccent;
                                            return lockIconBtn.hovered ? "white" : window.colMuted;
                                        }
                                        sourceSize: Qt.size(20, 20)
                                    }

                                    background: Rectangle {
                                        color: lockIconBtn.hovered ? "#33415520" : "transparent"
                                        radius: 16
                                    }

                                    onClicked: encryptionMenu.open()

                                    Popup {
                                        id: encryptionMenu
                                        y: lockIconBtn.height + 4
                                        x: -encryptionMenu.width + lockIconBtn.width
                                        width: 220
                                        padding: 8
                                        modal: true
                                        focus: true
                                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                                        background: Rectangle {
                                            color: window.colCard
                                            border.color: window.colBorder
                                            border.width: 1
                                            radius: 14
                                        }

                                        contentItem: ColumnLayout {
                                            spacing: 4

                                            Button {
                                                id: noEncBtn
                                                Layout.fillWidth: true
                                                implicitHeight: 40

                                                contentItem: RowLayout {
                                                    spacing: 10
                                                    TintedIcon {
                                                        Layout.leftMargin: 8
                                                        width: 18
                                                        height: 18
                                                        source: "icons/lock.svg"
                                                        color: window.colMuted
                                                        sourceSize: Qt.size(18, 18)
                                                    }
                                                    Text {
                                                        text: "No Encryption"
                                                        color: noEncBtn.hovered ? "white" : window.colText
                                                        font.pixelSize: 14
                                                        verticalAlignment: Text.AlignVCenter
                                                        Layout.fillWidth: true
                                                    }
                                                    Text {
                                                        visible: xmppBackend ? (xmppBackend.activeChatEncryptionMode === "No Encryption") : false
                                                        text: "✓"
                                                        color: window.colAccent
                                                        font.pixelSize: 16
                                                        font.bold: true
                                                        Layout.rightMargin: 8
                                                    }
                                                }

                                                background: Rectangle {
                                                    color: noEncBtn.hovered ? window.colPrimary : "transparent"
                                                    radius: 8
                                                }

                                                onClicked: {
                                                    encryptionMenu.close();
                                                    xmppBackend.setEncryptionEnabled(xmppBackend.activeChatJid, false);
                                                }
                                            }

                                            Button {
                                                id: omemoEncBtn
                                                Layout.fillWidth: true
                                                implicitHeight: 40

                                                contentItem: RowLayout {
                                                    spacing: 10
                                                    TintedIcon {
                                                        Layout.leftMargin: 8
                                                        width: 18
                                                        height: 18
                                                        source: "icons/lock.svg"
                                                        color: window.colPrimary
                                                        sourceSize: Qt.size(18, 18)
                                                    }
                                                    Text {
                                                        text: "OMEMO (E2EE)"
                                                        color: omemoEncBtn.hovered ? "white" : window.colText
                                                        font.pixelSize: 14
                                                        verticalAlignment: Text.AlignVCenter
                                                        Layout.fillWidth: true
                                                    }
                                                    Text {
                                                        visible: xmppBackend ? (xmppBackend.activeChatEncryptionMode === "OMEMO") : false
                                                        text: "✓"
                                                        color: window.colAccent
                                                        font.pixelSize: 16
                                                        font.bold: true
                                                        Layout.rightMargin: 8
                                                    }
                                                }

                                                background: Rectangle {
                                                    color: omemoEncBtn.hovered ? window.colPrimary : "transparent"
                                                    radius: 8
                                                }

                                                onClicked: {
                                                    encryptionMenu.close();
                                                    xmppBackend.setEncryptionEnabled(xmppBackend.activeChatJid, true);
                                                }
                                            }
                                        }
                                    }
                                }

                                Button {
                                    id: rightSidebarBtn
                                    implicitWidth: 32
                                    implicitHeight: 32

                                    contentItem: TintedIcon {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        source: "icons/view_sidebar.svg"
                                        color: root.showRightSidebar ? window.colAccent : (rightSidebarBtn.hovered ? "white" : window.colMuted)
                                        sourceSize: Qt.size(20, 20)
                                    }

                                    background: Rectangle {
                                        color: rightSidebarBtn.hovered ? "#33415520" : "transparent"
                                        radius: 16
                                    }

                                    onClicked: {
                                        root.showRightSidebar = !root.showRightSidebar;
                                    }
                                }

                                Button {
                                    id: moreHorizBtn
                                    implicitWidth: 32
                                    implicitHeight: 32

                                    contentItem: TintedIcon {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        source: "icons/more_horiz.svg"
                                        color: moreHorizBtn.hovered ? "white" : window.colMuted
                                        sourceSize: Qt.size(20, 20)
                                    }

                                    background: Rectangle {
                                        color: moreHorizBtn.hovered ? "#33415520" : "transparent"
                                        radius: 16
                                    }
                                }
                            }
                        }
                    }

                    // Message History List View
                    ListView {
                        id: chatHistoryView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: chatModel
                        delegate: MessageDelegate {}
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: false

                        // Align messages to bottom when history is shorter than view height (without animation to prevent scroll bounds desync)
                        topMargin: Math.max(8, height - contentHeight)
                        bottomMargin: 8

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        // Speed up wheel scrolling using a pass-through MouseArea
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: wheel => {
                                if (chatHistoryView.contentHeight > chatHistoryView.height && wheel.angleDelta.y !== 0) {
                                    var newY = chatHistoryView.contentY - wheel.angleDelta.y * 0.4;
                                    var maxY = Math.max(chatHistoryView.originY, chatHistoryView.contentHeight - chatHistoryView.height);
                                    chatHistoryView.contentY = Math.max(chatHistoryView.originY, Math.min(newY, maxY));
                                    wheel.accepted = true;
                                }
                            }
                        }

                        // Auto-scroll on new message (Qt.callLater ensures new delegates are loaded/positioned before scrolling)
                        onCountChanged: {
                            Qt.callLater(chatHistoryView.positionViewAtEnd);
                        }
                    }

                    // Message Editing Panel
                    InteractMessagePanelDelegate {
                        id: interactmessagepaneldelegate
                        editingMsgId: root.editingMsgId
                        editingText: root.editingMsgText
                        editingRowIndex: root.editingRowIndex
                        onCancelRequested: root.cancelEditing()
                        onJumpRequested: root.scrollToEditingMessage()
                    }

                    // Message Input Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 46
                        color: window.colInputBg

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: window.colBorder
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 12

                            Button {
                                id: attachBtn
                                implicitWidth: 32
                                implicitHeight: 32

                                contentItem: TintedIcon {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    source: "icons/attach_file.svg"
                                    color: attachBtn.hovered ? "white" : window.colMuted
                                    sourceSize: Qt.size(20, 20)
                                }

                                background: Rectangle {
                                    color: attachBtn.hovered ? "#33415520" : "transparent"
                                    radius: 16
                                }

                                onClicked: attachMenu.open()

                                Popup {
                                    id: attachMenu
                                    y: -attachMenu.height - 8
                                    x: 0
                                    width: 220
                                    padding: 8
                                    modal: true
                                    focus: true
                                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                                    background: Rectangle {
                                        color: window.colCard
                                        border.color: window.colBorder
                                        border.width: 1
                                        radius: 14
                                    }

                                    contentItem: ColumnLayout {
                                        spacing: 4

                                        Button {
                                            id: attachImageBtn
                                            Layout.fillWidth: true
                                            implicitHeight: 44

                                            contentItem: RowLayout {
                                                spacing: 14
                                                TintedIcon {
                                                    Layout.leftMargin: 10
                                                    width: 24
                                                    height: 24
                                                    source: "icons/image.svg"
                                                    color: attachImageBtn.hovered ? "white" : window.colMuted
                                                    sourceSize: Qt.size(24, 24)
                                                }
                                                Text {
                                                    text: "Photo or Video"
                                                    color: attachImageBtn.hovered ? "white" : window.colText
                                                    font.pixelSize: 15
                                                    verticalAlignment: Text.AlignVCenter
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            background: Rectangle {
                                                color: attachImageBtn.hovered ? window.colPrimary : "transparent"
                                                radius: 10
                                            }

                                            onClicked: {
                                                attachMenu.close();
                                                fileDialog.title = "Select Image or Video to Upload";
                                                fileDialog.nameFilters = ["Media files (*.png *.jpg *.jpeg *.gif *.webp *.mp4 *.webm *.mkv)"];
                                                fileDialog.open();
                                            }
                                        }

                                        Button {
                                            id: attachFileBtn
                                            Layout.fillWidth: true
                                            implicitHeight: 44

                                            contentItem: RowLayout {
                                                spacing: 14
                                                TintedIcon {
                                                    Layout.leftMargin: 10
                                                    width: 24
                                                    height: 24
                                                    source: "icons/description.svg"
                                                    color: attachFileBtn.hovered ? "white" : window.colMuted
                                                    sourceSize: Qt.size(24, 24)
                                                }
                                                Text {
                                                    text: "File"
                                                    color: attachFileBtn.hovered ? "white" : window.colText
                                                    font.pixelSize: 15
                                                    verticalAlignment: Text.AlignVCenter
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            background: Rectangle {
                                                color: attachFileBtn.hovered ? window.colPrimary : "transparent"
                                                radius: 10
                                            }

                                            onClicked: {
                                                attachMenu.close();
                                                fileDialog.title = "Select File to Upload";
                                                fileDialog.nameFilters = ["All files (*)"];
                                                fileDialog.open();
                                            }
                                        }

                                        Button {
                                            id: attachLocationBtn
                                            Layout.fillWidth: true
                                            implicitHeight: 44

                                            contentItem: RowLayout {
                                                spacing: 14
                                                TintedIcon {
                                                    Layout.leftMargin: 10
                                                    width: 24
                                                    height: 24
                                                    source: "icons/location_on.svg"
                                                    color: attachLocationBtn.hovered ? "white" : window.colMuted
                                                    sourceSize: Qt.size(24, 24)
                                                }
                                                Text {
                                                    text: "Location"
                                                    color: attachLocationBtn.hovered ? "white" : window.colText
                                                    font.pixelSize: 15
                                                    verticalAlignment: Text.AlignVCenter
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            background: Rectangle {
                                                color: attachLocationBtn.hovered ? window.colPrimary : "transparent"
                                                radius: 10
                                            }

                                            onClicked: {
                                                attachMenu.close();
                                                xmppBackend.sendMessage("https://www.openstreetmap.org/?mlat=50.4501&mlon=30.5234");
                                            }
                                        }
                                    }
                                }
                            }

                            TextField {
                                id: messageInput
                                placeholderText: root.editingMsgId !== 0 ? "Edit message..." : "Type a message..."
                                placeholderTextColor: "#4b5563"
                                color: window.colText
                                Layout.fillWidth: true
                                font.pixelSize: 14
                                selectByMouse: true
                                leftPadding: 0
                                rightPadding: 0

                                background: Rectangle {
                                    color: "transparent"
                                }

                                Keys.onPressed: event => {
                                    if ((event.key === Qt.Key_V) && (event.modifiers & Qt.ControlModifier)) {
                                        var clipUrl = xmppBackend.getClipboardImageOrFile();
                                        if (clipUrl && clipUrl !== "") {
                                            event.accepted = true;
                                            root.confirmSendFile(clipUrl);
                                        }
                                    } else if (event.key === Qt.Key_Escape && root.editingMsgId !== 0) {
                                        event.accepted = true;
                                        root.cancelEditing();
                                    } else if (event.key === Qt.Key_Up && messageInput.text === "" && root.editingMsgId === 0) {
                                        var lastMsg = chatModel.getLastMyMessage();
                                        if (lastMsg && lastMsg.msgId) {
                                            event.accepted = true;
                                            root.startEditingMessage(lastMsg.msgId, lastMsg.body, lastMsg.index);
                                        }
                                    }
                                }

                                onTextChanged: {
                                    if (xmppBackend && xmppBackend.activeChatJid !== "" && root.editingMsgId === 0) {
                                        xmppBackend.sendTypingNotification(xmppBackend.activeChatJid, text.trim().length > 0);
                                    }
                                }

                                onAccepted: {
                                    var txt = text.trim();
                                    if (txt !== "") {
                                        if (xmppBackend && xmppBackend.activeChatJid !== "") {
                                            xmppBackend.sendTypingNotification(xmppBackend.activeChatJid, false);
                                        }
                                        if (root.editingMsgId !== 0) {
                                            xmppBackend.editMessage(root.editingMsgId, txt);
                                            root.cancelEditing();
                                        } else {
                                            xmppBackend.sendMessage(txt);
                                            text = "";
                                        }
                                    }
                                }
                            }

                            Button {
                                id: sendBtn
                                implicitWidth: 32
                                implicitHeight: 32
                                visible: messageInput.text.trim() !== "" || root.editingMsgId !== 0

                                contentItem: TintedIcon {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    source: root.editingMsgId !== 0 ? "icons/check.svg" : "icons/send.svg"
                                    color: sendBtn.down ? window.colPrimaryDark : (sendBtn.hovered ? window.colAccent : window.colPrimary)
                                    sourceSize: Qt.size(18, 18)
                                }

                                background: Rectangle {
                                    color: sendBtn.hovered ? "#33415520" : "transparent"
                                    radius: 16
                                }

                                onClicked: {
                                    var txt = messageInput.text.trim();
                                    if (txt !== "") {
                                        if (root.editingMsgId !== 0) {
                                            xmppBackend.editMessage(root.editingMsgId, txt);
                                            root.cancelEditing();
                                        } else {
                                            xmppBackend.sendMessage(txt);
                                            messageInput.text = "";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                DropArea {
                    id: chatDropArea
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: (root.showRightSidebar && (xmppBackend ? xmppBackend.activeChatJid !== "" : false)) ? contactSidebar.left : parent.right
                    keys: ["text/uri-list"]

                    onEntered: drag => {
                        if (drag.hasUrls) {
                            drag.accept(Qt.CopyAction);
                        }
                    }

                    onDropped: drop => {
                        if (drop.hasUrls && drop.urls.length > 0) {
                            var url = drop.urls[0].toString();
                            root.confirmSendFile(url);
                            drop.accept();
                        }
                    }
                }

                // Visual Drop Overlay
                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: (root.showRightSidebar && (xmppBackend ? xmppBackend.activeChatJid !== "" : false)) ? contactSidebar.left : parent.right
                    z: 99
                    visible: chatDropArea.containsDrag
                    color: "#0f172ae6"
                    border.color: window.colPrimary
                    border.width: 3
                    radius: 8

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            width: 48
                            height: 48
                            source: "icons/attach_file_white.svg"
                            sourceSize: Qt.size(48, 48)
                        }

                        Text {
                            text: "Drop image or file to send"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Sending to " + (xmppBackend ? xmppBackend.activeChatJid : "")
                            color: window.colMuted
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Right Sidebar (Contact Details)
                ContactDetailSidebar {
                    id: contactSidebar
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 320
                    z: 50
                    visible: root.showRightSidebar && (xmppBackend ? xmppBackend.activeChatJid !== "" : false)
                    contactJid: xmppBackend ? xmppBackend.activeChatJid : ""
                    contactName: (xmppBackend && xmppBackend.activeChatJid) ? xmppBackend.activeChatJid.split('@')[0] : ""
                    contactAvatar: xmppBackend ? xmppBackend.activeChatAvatar : ""
                    contactLastSeen: xmppBackend ? xmppBackend.activeChatLastSeen : ""

                    onCloseRequested: {
                        root.showRightSidebar = false;
                    }
                }
            }
        }

        FileDialog {
            id: fileDialog
            title: "Select File to Upload"
            onAccepted: {
                root.confirmSendFile(selectedFile.toString());
            }
        }

        Dialog {
            id: sendFileConfirmDialog
            anchors.centerIn: parent
            modal: true
            focus: true
            padding: 24

            property string fileUrl: ""
            property string fileSize: ""
            property alias captionText: sendFileCaptionInput.text

            property bool isImageFile: {
                if (!fileUrl)
                    return false;
                var t = fileUrl.toLowerCase();
                return t.indexOf(".png") !== -1 || t.indexOf(".jpg") !== -1 || t.indexOf(".jpeg") !== -1 || t.indexOf(".gif") !== -1 || t.indexOf(".webp") !== -1 || t.indexOf(".bmp") !== -1;
            }

            background: Rectangle {
                color: window.colCard
                border.color: window.colBorder
                border.width: 1
                radius: 12
            }

            contentItem: ColumnLayout {
                spacing: 16
                width: 360

                Text {
                    text: "Confirm Send File"
                    color: window.colText
                    font.pixelSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignLeft
                }

                Text {
                    text: "Send file to: " + (xmppBackend ? xmppBackend.activeChatJid : "")
                    color: window.colMuted
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Preview Container
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sendFileConfirmDialog.isImageFile ? 220 : 70
                    color: window.colInputBg
                    border.color: window.colBorder
                    radius: 8
                    clip: true

                    Image {
                        visible: sendFileConfirmDialog.isImageFile
                        anchors.fill: parent
                        anchors.margins: 8
                        source: sendFileConfirmDialog.fileUrl
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    RowLayout {
                        visible: !sendFileConfirmDialog.isImageFile
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Image {
                            width: 36
                            height: 36
                            source: "icons/attach_file_white.svg"
                            sourceSize: Qt.size(36, 36)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: {
                                    var parts = sendFileConfirmDialog.fileUrl.split("/");
                                    return parts[parts.length - 1] || "Selected File";
                                }
                                color: window.colText
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            Text {
                                text: sendFileConfirmDialog.fileSize
                                color: window.colMuted
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // Optional Caption Input
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    color: window.colInputBg
                    border.color: window.colBorder
                    radius: 6

                    TextField {
                        id: sendFileCaptionInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        placeholderText: "Add an optional caption..."
                        placeholderTextColor: "#4b5563"
                        color: window.colText
                        font.pixelSize: 13
                        background: Rectangle {
                            color: "transparent"
                        }
                    }
                }

                // Action Buttons
                RowLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    Button {
                        id: cancelSendFileBtn
                        Layout.fillWidth: true
                        implicitHeight: 36

                        contentItem: Text {
                            text: "Cancel"
                            color: window.colText
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: cancelSendFileBtn.hovered ? "#33415540" : "transparent"
                            border.color: window.colBorder
                            radius: 6
                        }

                        onClicked: sendFileConfirmDialog.close()
                    }

                    Button {
                        id: confirmSendFileBtn
                        Layout.fillWidth: true
                        implicitHeight: 36

                        contentItem: Text {
                            text: "Send File"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: confirmSendFileBtn.down ? window.colPrimaryDark : (confirmSendFileBtn.hovered ? window.colAccent : window.colPrimary)
                            radius: 6
                        }

                        onClicked: {
                            var url = sendFileConfirmDialog.fileUrl;
                            var caption = sendFileCaptionInput.text.trim();
                            sendFileConfirmDialog.close();
                            xmppBackend.uploadFile(url);
                            if (caption !== "") {
                                xmppBackend.sendMessage(caption);
                            }
                        }
                    }
                }
            }
        }

        Dialog {
            id: imagePreviewDialog
            anchors.centerIn: parent
            modal: true
            focus: true
            padding: 0
            property string imageSource: ""
            property string resolvedPreviewSource: imagePreviewDialog.imageSource ? xmppBackend.getResolvedMediaUrl(imagePreviewDialog.imageSource) : ""

            Connections {
                target: xmppBackend
                function onMediaUrlResolved(origUrl, resolvedUrl) {
                    if (origUrl === imagePreviewDialog.imageSource) {
                        imagePreviewDialog.resolvedPreviewSource = resolvedUrl;
                    }
                }
            }

            onImageSourceChanged: {
                resolvedPreviewSource = imagePreviewDialog.imageSource ? xmppBackend.getResolvedMediaUrl(imagePreviewDialog.imageSource) : "";
            }

            background: Rectangle {
                color: "#1e293bcc"
                radius: 12
                border.color: window.colBorder
                border.width: 1
            }

            contentItem: Item {
                implicitWidth: Math.min(root.width * 0.85, 700)
                implicitHeight: Math.min(root.height * 0.85, 550)

                Image {
                    anchors.fill: parent
                    anchors.margins: 16
                    source: imagePreviewDialog.resolvedPreviewSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            previewContextMenu.popup();
                        }
                    }
                }

                Menu {
                    id: previewContextMenu
                    padding: 6
                    background: Rectangle {
                        implicitWidth: 180
                        color: window.colCard
                        border.color: window.colBorder
                        radius: 8
                    }
                    MenuItem {
                        id: savePreviewItem
                        text: "Save image as..."
                        implicitWidth: 168
                        implicitHeight: 36
                        contentItem: Text {
                            text: savePreviewItem.text
                            color: savePreviewItem.hovered ? "white" : window.colText
                            font.pixelSize: 14
                            leftPadding: 8
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: savePreviewItem.hovered ? window.colPrimary : "transparent"
                            radius: 6
                        }
                        onTriggered: {
                            xmppBackend.saveImageAs(imagePreviewDialog.imageSource);
                        }
                    }
                }

                RowLayout {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 8

                    Button {
                        id: savePreviewBtn
                        implicitWidth: 32
                        implicitHeight: 32

                        contentItem: Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: "icons/download_white.svg"
                            sourceSize: Qt.size(18, 18)
                        }

                        background: Rectangle {
                            color: savePreviewBtn.hovered ? window.colPrimary : "#00000080"
                            radius: 16
                        }

                        onClicked: xmppBackend.saveImageAs(imagePreviewDialog.imageSource)
                    }

                    Button {
                        implicitWidth: 32
                        implicitHeight: 32

                        contentItem: Text {
                            text: "✕"
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: "#00000080"
                            radius: 16
                        }

                        onClicked: imagePreviewDialog.close()
                    }
                }
            }
        }
    }
}
