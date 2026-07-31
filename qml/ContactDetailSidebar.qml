import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: sidebarRoot
    width: 320
    color: window.colCard
    border.color: window.colBorder
    border.width: 1

    property string contactJid: ""
    property string contactName: ""
    property string contactAvatar: ""
    property string contactStatus: "offline"
    property string contactLastSeen: ""
    property string contactStatusMessage: ""

    signal closeRequested

    function refreshContactData() {
        if (!contactJid || contactJid === "")
            return;
        isBlocked = xmppBackend.isContactBlocked(contactJid);
        fingerprintsModel.clear();
        var fps = xmppBackend.getContactFingerprints(contactJid);
        for (var i = 0; i < fps.length; i++) {
            fingerprintsModel.append(fps[i]);
        }
    }

    onContactJidChanged: refreshContactData()

    ListModel {
        id: fingerprintsModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: window.sidebarHeaderBg
            border.color: window.colBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12

                Text {
                    text: "User Info"
                    color: window.colText
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                Button {
                    implicitWidth: 32
                    implicitHeight: 32
                    contentItem: Text {
                        text: "✕"
                        color: window.colMuted
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#33415530" : "transparent"
                        radius: 16
                    }
                    onClicked: sidebarRoot.closeRequested()
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: 20
                anchors.topMargin: 20
                anchors.bottomMargin: 20

                // Avatar & Name Card
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 84
                        height: 84
                        radius: 42
                        color: "#3b82f6"
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            visible: sidebarAvatarImg.status !== Image.Ready
                            text: sidebarRoot.contactJid ? sidebarRoot.contactJid.substring(0, 1).toUpperCase() : "?"
                            color: "white"
                            font.pixelSize: 32
                            font.bold: true
                        }

                        Image {
                            id: sidebarAvatarImg
                            anchors.fill: parent
                            source: sidebarRoot.contactAvatar
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }

                    Text {
                        text: sidebarRoot.contactName ? sidebarRoot.contactName : (sidebarRoot.contactJid ? sidebarRoot.contactJid.split('@')[0] : "")
                        color: window.colText
                        font.pixelSize: 18
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        text: sidebarRoot.contactLastSeen ? sidebarRoot.contactLastSeen : "Offline"
                        color: sidebarRoot.contactLastSeen === "typing..." ? window.colAccent : window.colMuted
                        font.pixelSize: 13
                        font.italic: sidebarRoot.contactLastSeen === "typing..."
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Action Buttons (Chat & Call)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Button {
                        id: chatActionBtn
                        implicitWidth: 110
                        implicitHeight: 38

                        contentItem: RowLayout {
                            spacing: 8
                            Image {
                                width: 18
                                height: 18
                                source: "icons/chat_muted.svg"
                                sourceSize: Qt.size(18, 18)
                            }
                            Text {
                                text: "Message"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 13
                            }
                        }

                        background: Rectangle {
                            color: chatActionBtn.down ? window.colPrimaryDark : (chatActionBtn.hovered ? window.colAccent : window.colPrimary)
                            radius: 8
                        }

                        onClicked: {
                            xmppBackend.selectChat(sidebarRoot.contactJid);
                        }
                    }

                    Button {
                        id: callActionBtn
                        implicitWidth: 110
                        implicitHeight: 38

                        contentItem: RowLayout {
                            spacing: 8
                            Image {
                                width: 18
                                height: 18
                                source: "icons/location_on_muted.svg"
                                sourceSize: Qt.size(18, 18)
                            }
                            Text {
                                text: "Call"
                                color: window.colText
                                font.pixelSize: 13
                            }
                        }

                        background: Rectangle {
                            color: callActionBtn.hovered ? "#33415530" : "transparent"
                            border.color: window.colBorder
                            radius: 8
                        }

                        onClicked: {
                            // Call placeholder action
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: window.colBorder
                }

                // JID & Details Section
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 14

                    Text {
                        text: "Account Details"
                        color: window.colMuted
                        font.pixelSize: 12
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Image {
                            width: 20
                            height: 20
                            source: "icons/chat_muted.svg"
                            sourceSize: Qt.size(20, 20)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: sidebarRoot.contactJid
                                color: window.colText
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "Username / JID"
                                color: window.colMuted
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: window.colBorder
                }

                // OMEMO Signatures Section
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "OMEMO Keys & Signatures"
                            color: window.colMuted
                            font.pixelSize: 12
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Button {
                            implicitWidth: 24
                            implicitHeight: 24
                            contentItem: Text {
                                text: "↻"
                                color: window.colAccent
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: "transparent"
                            }
                            onClicked: sidebarRoot.refreshContactData()
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: fingerprintsModel.count > 0

                        Repeater {
                            model: fingerprintsModel
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 56
                                color: window.colInputBg
                                border.color: window.colBorder
                                radius: 8

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2

                                    Text {
                                        text: "Device ID: " + model.device_id
                                        color: window.colText
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        text: model.fingerprint
                                        color: window.colAccent
                                        font.pixelSize: 10
                                        font.family: "Monospace"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: fingerprintsModel.count === 0
                        text: "No OMEMO keys retrieved for this contact yet."
                        color: window.colMuted
                        font.pixelSize: 12
                        font.italic: true
                    }

                    Button {
                        id: cleanKeysBtn
                        Layout.fillWidth: true
                        implicitHeight: 34

                        contentItem: RowLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignHCenter
                            Image {
                                width: 14
                                height: 14
                                source: "icons/lock_white.svg"
                                sourceSize: Qt.size(14, 14)
                            }
                            Text {
                                text: "Clean All OMEMO Keys"
                                color: "#ef4444"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        background: Rectangle {
                            color: cleanKeysBtn.down ? "#dc262625" : (cleanKeysBtn.hovered ? "#ef444415" : "transparent")
                            border.color: "#ef444460"
                            border.width: 1
                            radius: 8
                        }

                        onClicked: {
                            confirmCleanKeysDialog.open();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: window.colBorder
                }

                // Contact Actions Section (Change Contact Name & Delete Contact)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    spacing: 8

                    Button {
                        id: renameBtn
                        Layout.fillWidth: true
                        implicitHeight: 42

                        contentItem: RowLayout {
                            spacing: 12
                            Image {
                                Layout.leftMargin: 10
                                width: 20
                                height: 20
                                source: "icons/description_muted.svg"
                                sourceSize: Qt.size(20, 20)
                            }
                            Text {
                                text: "Change Contact Name"
                                color: window.colText
                                font.pixelSize: 14
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }

                        background: Rectangle {
                            color: renameBtn.hovered ? "#33415530" : "transparent"
                            radius: 8
                        }

                        onClicked: renameDialog.open()
                    }

                    Button {
                        id: blockBtn
                        Layout.fillWidth: true
                        implicitHeight: 42
                        visible: !sidebarRoot.isBlocked

                        contentItem: RowLayout {
                            spacing: 12
                            TintedIcon {
                                Layout.leftMargin: 10
                                width: 20
                                height: 20
                                source: "icons/back_hand.svg"
                                color: "#ef4444"
                                sourceSize: Qt.size(20, 20)
                            }
                            Text {
                                text: "Block Contact"
                                color: "#ef4444"
                                font.pixelSize: 14
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }

                        background: Rectangle {
                            color: blockBtn.hovered ? "#ef444415" : "transparent"
                            border.color: "#ef444460"
                            border.width: 1
                            radius: 8
                        }

                        onClicked: {
                            xmppBackend.blockContact(sidebarRoot.contactJid);
                            sidebarRoot.isBlocked = true;
                        }
                    }

                    Button {
                        id: reportSpamBtn
                        Layout.fillWidth: true
                        implicitHeight: 42
                        visible: !sidebarRoot.isBlocked

                        contentItem: RowLayout {
                            spacing: 12
                            TintedIcon {
                                Layout.leftMargin: 10
                                width: 20
                                height: 20
                                source: "icons/report.svg"
                                color: "#ef4444"
                                sourceSize: Qt.size(20, 20)
                            }
                            Text {
                                text: "Report & Block (Spam)"
                                color: "#ef4444"
                                font.pixelSize: 14
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }

                        background: Rectangle {
                            color: reportSpamBtn.hovered ? "#ef444415" : "transparent"
                            border.color: "#ef444460"
                            border.width: 1
                            radius: 8
                        }

                        onClicked: {
                            xmppBackend.reportAndBlockContact(sidebarRoot.contactJid, "spam");
                            sidebarRoot.isBlocked = true;
                        }
                    }

                    Button {
                        id: unblockBtn
                        Layout.fillWidth: true
                        implicitHeight: 42
                        visible: sidebarRoot.isBlocked

                        contentItem: RowLayout {
                            spacing: 12
                            TintedIcon {
                                Layout.leftMargin: 10
                                width: 20
                                height: 20
                                source: "icons/check.svg"
                                color: window.colPrimary
                                sourceSize: Qt.size(20, 20)
                            }
                            Text {
                                text: "Unblock Contact"
                                color: window.colPrimary
                                font.pixelSize: 14
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }

                        background: Rectangle {
                            color: unblockBtn.hovered ? "#33415530" : "transparent"
                            border.color: window.colPrimary
                            border.width: 1
                            radius: 8
                        }

                        onClicked: {
                            xmppBackend.unblockContact(sidebarRoot.contactJid);
                            sidebarRoot.isBlocked = false;
                        }
                    }

                    Button {
                        id: deleteBtn
                        Layout.fillWidth: true
                        implicitHeight: 42

                        contentItem: RowLayout {
                            spacing: 12
                            Image {
                                Layout.leftMargin: 10
                                width: 20
                                height: 20
                                source: "icons/error_red.svg"
                                sourceSize: Qt.size(20, 20)
                            }
                            Text {
                                text: "Delete Contact"
                                color: "#ef4444"
                                font.pixelSize: 14
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }

                        background: Rectangle {
                            color: deleteBtn.hovered ? "#ef444415" : "transparent"
                            radius: 8
                        }

                        onClicked: deleteConfirmDialog.open()
                    }
                }
            }
        }
    }

    // Rename Contact Dialog
    Dialog {
        id: renameDialog
        anchors.centerIn: Overlay.overlay
        modal: true
        focus: true
        padding: 20
        width: 320

        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 12
        }

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: "Change Contact Name"
                color: window.colText
                font.pixelSize: 16
                font.bold: true
            }

            TextField {
                id: renameInput
                Layout.fillWidth: true
                text: sidebarRoot.contactName
                placeholderText: "Enter contact name..."
                color: window.colText
                font.pixelSize: 14
                selectByMouse: true

                background: Rectangle {
                    color: window.colInputBg
                    border.color: window.colBorder
                    radius: 6
                }
            }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignRight

                Button {
                    text: "Cancel"
                    onClicked: renameDialog.close()
                }

                Button {
                    id: saveRenameBtn
                    contentItem: Text {
                        text: "Save"
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        color: window.colPrimary
                        radius: 6
                    }
                    onClicked: {
                        if (renameInput.text.trim() !== "") {
                            xmppBackend.renameContact(sidebarRoot.contactJid, renameInput.text.trim());
                            sidebarRoot.contactName = renameInput.text.trim();
                            renameDialog.close();
                        }
                    }
                }
            }
        }
    }

    // Delete Confirmation Dialog
    Dialog {
        id: deleteConfirmDialog
        anchors.centerIn: Overlay.overlay
        modal: true
        focus: true
        padding: 20
        width: 320

        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 12
        }

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: "Delete Contact"
                color: "#ef4444"
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                text: "Are you sure you want to remove " + sidebarRoot.contactJid + " from your contacts and delete chat history?"
                color: window.colText
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignRight

                Button {
                    text: "Cancel"
                    onClicked: deleteConfirmDialog.close()
                }

                Button {
                    contentItem: Text {
                        text: "Delete"
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        color: "#ef4444"
                        radius: 6
                    }
                    onClicked: {
                        deleteConfirmDialog.close();
                        sidebarRoot.closeRequested();
                        xmppBackend.deleteContact(sidebarRoot.contactJid);
                    }
                }
            }
        }
    }

    Dialog {
        id: confirmCleanKeysDialog
        title: "Clean All OMEMO Keys"
        width: 320
        anchors.centerIn: Overlay.overlay
        modal: true
        padding: 20

        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            radius: 12
        }

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: "Clean All OMEMO Keys"
                color: "#ef4444"
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                text: "This will wipe all local identity keys, active ratchets, and cached peer bundles, then publish fresh OMEMO keys to PEP. Continue?"
                color: window.colText
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.preferredWidth: 280
            }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignRight

                Button {
                    text: "Cancel"
                    onClicked: confirmCleanKeysDialog.close()
                }

                Button {
                    contentItem: Text {
                        text: "Clean Keys"
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        color: "#ef4444"
                        radius: 6
                    }
                    onClicked: {
                        confirmCleanKeysDialog.close();
                        var ok = xmppBackend.cleanOmemoKeys();
                        if (ok) {
                            sidebarRoot.refreshContactData();
                        }
                    }
                }
            }
        }
    }
}
