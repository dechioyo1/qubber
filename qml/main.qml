import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1050
    height: 720
    minimumWidth: 850
    minimumHeight: 600
    visible: true
    title: "Qubber - XMPP Client"
    flags: Qt.Window | Qt.FramelessWindowHint
    
    color: window.colBg
    
    readonly property bool isNormalWindow: window.visibility !== Window.Maximized && window.visibility !== Window.FullScreen

    // Theme palette bound dynamically to themeManager
    readonly property color colPrimary: themeManager.colPrimary
    readonly property color colPrimaryDark: themeManager.colPrimaryDark
    readonly property color colAccent: themeManager.colAccent
    readonly property color colBg: themeManager.colBg
    readonly property color colCard: themeManager.colCard
    readonly property color colText: themeManager.colText
    readonly property color colMuted: themeManager.colMuted
    readonly property color colBorder: themeManager.colBorder
    readonly property color colInputBg: themeManager.colInputBg
    readonly property color topBarBg: themeManager.topBarBg
    readonly property color topBarFg: themeManager.topBarFg
    readonly property color sidebarBg: themeManager.sidebarBg
    readonly property color sidebarHeaderBg: themeManager.sidebarHeaderBg
    readonly property color sidebarBgOver: themeManager.sidebarBgOver
    readonly property color sidebarBgActive: themeManager.sidebarBgActive
    readonly property color msgInBg: themeManager.msgInBg
    readonly property color msgInText: themeManager.msgInText
    readonly property color msgOutBg: themeManager.msgOutBg
    readonly property color msgOutText: themeManager.msgOutText

    // Presence colors
    readonly property color colOnline: "#10b981"
    readonly property color colAway: "#f59e0b"
    readonly property color colDnd: "#ef4444"
    readonly property color colOffline: "#64748b"

    background: Rectangle {
        color: window.colBg
    }
    
    // Listen to global backend connection changes
    Connections {
        target: xmppBackend
        
        function onSubscriptionRequested(jid) {
            subscriptionDialog.requesterJid = jid
            subscriptionDialog.open()
        }
        
        function onConnectionStatusChanged(status) {
            if (status === "Connected") {
                if (mainStack.currentIndex === 0) {
                    mainStack.currentIndex = 1
                }
            } else if (status === "Disconnected" || status === "Authentication failed" || status.startsWith("Error")) {
                mainStack.currentIndex = 0
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Custom CSD Header Bar (34px height)
        Rectangle {
            id: titleBar
            Layout.fillWidth: true
            height: 34
            color: window.topBarBg
            
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: window.colBorder
            }

            // Window drag MouseArea (sits at back)
            MouseArea {
                anchors.fill: parent
                onPressed: window.startSystemMove()
                onDoubleClicked: {
                    if (window.visibility === Window.Maximized) {
                        window.showNormal()
                    } else {
                        window.showMaximized()
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 4
                spacing: 12

                // Qubber Logo and Title Menu Button
                Button {
                    id: qubberBtn
                    implicitHeight: 26
                    
                    background: Rectangle {
                        color: qubberBtn.hovered ? "#33415530" : "transparent"
                        radius: 6
                    }
                    
                    contentItem: RowLayout {
                        spacing: 8
                        Image {
                            width: 18
                            height: 18
                            source: "../logo.svg"
                            sourceSize: Qt.size(18, 18)
                        }
                        Text {
                            text: "Qubber"
                            color: qubberBtn.hovered ? window.colText : window.topBarFg
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    
                    onClicked: {
                        qubberMenu.open()
                    }

                    Popup {
                        id: qubberMenu
                        y: parent.height + 4
                        x: 0
                        width: 160
                        padding: 6
                        modal: false
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        
                        background: Rectangle {
                            color: window.colCard
                            border.color: window.colBorder
                            radius: 8
                        }
                        
                        contentItem: ColumnLayout {
                            spacing: 4
                            
                            Button {
                                id: aboutMenuBtn
                                Layout.fillWidth: true
                                implicitHeight: 36
                                
                                contentItem: Text {
                                    text: "About Qubber"
                                    color: aboutMenuBtn.hovered ? "white" : window.colText
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: aboutMenuBtn.hovered ? window.colPrimary : "transparent"
                                    radius: 6
                                }
                                
                                onClicked: {
                                    qubberMenu.close()
                                    aboutDialog.open()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: window.colBorder
                            }

                            Button {
                                id: exitMenuBtn
                                Layout.fillWidth: true
                                implicitHeight: 36
                                
                                contentItem: Text {
                                    text: "Exit"
                                    color: exitMenuBtn.hovered ? "white" : window.colText
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: exitMenuBtn.hovered ? "#ef4444" : "transparent"
                                    radius: 6
                                }
                                
                                onClicked: {
                                    qubberMenu.close()
                                    window.close()
                                }
                            }
                        }
                    }
                }

                // Menubar menu items (Contacts & Account)
                // Visible only when logged in (currentIndex is not 0)
                RowLayout {
                    spacing: 4
                    visible: mainStack.currentIndex !== 0

                    Button {
                        id: contactsBtn
                        implicitHeight: 26
                        
                        contentItem: Text {
                            text: "Contacts"
                            color: contactsBtn.hovered ? window.colText : window.topBarFg
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: contactsBtn.hovered ? "#33415530" : "transparent"
                            radius: 6
                        }
                        
                        onClicked: {
                            contactsMenu.open()
                        }

                        Popup {
                            id: contactsMenu
                            y: parent.height + 4
                            x: 0
                            width: 160
                            padding: 6
                            modal: false
                            focus: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            
                            background: Rectangle {
                                color: window.colCard
                                border.color: window.colBorder
                                radius: 8
                            }
                            
                            contentItem: ColumnLayout {
                                spacing: 4
                                
                                Button {
                                    id: listContactsMenuBtn
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    
                                    contentItem: Text {
                                        text: "List Contacts"
                                        color: listContactsMenuBtn.hovered ? "white" : window.colText
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    
                                    background: Rectangle {
                                        color: listContactsMenuBtn.hovered ? window.colPrimary : "transparent"
                                        radius: 6
                                    }
                                    
                                    onClicked: {
                                        contactsMenu.close()
                                        contactsListPopup.open()
                                    }
                                }

                                Button {
                                    id: addContactMenuBtn
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    
                                    contentItem: Text {
                                        text: "Add Contact..."
                                        color: addContactMenuBtn.hovered ? "white" : window.colText
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    
                                    background: Rectangle {
                                        color: addContactMenuBtn.hovered ? window.colPrimary : "transparent"
                                        radius: 6
                                    }
                                    
                                    onClicked: {
                                        contactsMenu.close()
                                        addContactDialog.open()
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        id: accountBtn
                        implicitHeight: 26
                        
                        contentItem: Text {
                            text: xmppBackend.myJid !== "" ? xmppBackend.myJid : "Account"
                            color: accountBtn.hovered ? window.colText : window.topBarFg
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: accountBtn.hovered ? "#33415530" : "transparent"
                            radius: 6
                        }
                        
                        onClicked: {
                            accountMenu.open()
                        }

                        Popup {
                            id: accountMenu
                            y: parent.height + 4
                            x: 0
                            width: 170
                            padding: 6
                            modal: false
                            focus: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            
                            background: Rectangle {
                                color: window.colCard
                                border.color: window.colBorder
                                radius: 8
                            }
                            
                            contentItem: ColumnLayout {
                                spacing: 4
                                
                                Button {
                                    id: changeStatusMenuBtn
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    
                                    contentItem: Text {
                                        text: "Change Status..."
                                        color: changeStatusMenuBtn.hovered ? "white" : window.colText
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    
                                    background: Rectangle {
                                        color: changeStatusMenuBtn.hovered ? window.colPrimary : "transparent"
                                        radius: 6
                                    }
                                    
                                    onClicked: {
                                        accountMenu.close()
                                        changeStatusPopup.open()
                                    }
                                }

                                Button {
                                    id: logoutMenuBtn
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    
                                    contentItem: Text {
                                        text: "Logout"
                                        color: logoutMenuBtn.hovered ? "white" : window.colText
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    
                                    background: Rectangle {
                                        color: logoutMenuBtn.hovered ? window.colPrimary : "transparent"
                                        radius: 6
                                    }
                                    
                                    onClicked: {
                                        accountMenu.close()
                                        xmppBackend.logout()
                                    }
                                }
                            }
                        }
                    }
                }

                // Spacer
                Item {
                    Layout.fillWidth: true
                }

                // Window Control Buttons (height matches titleBar)
                RowLayout {
                    spacing: 0
                    
                    Button {
                        id: minBtn
                        implicitWidth: 44
                        implicitHeight: 34
                        
                        contentItem: Text {
                            text: "—"
                            color: minBtn.hovered ? window.colText : window.topBarFg
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: minBtn.down ? "#33415560" : (minBtn.hovered ? "#33415530" : "transparent")
                        }
                        
                        onClicked: window.showMinimized()
                    }

                    Button {
                        id: maxBtn
                        implicitWidth: 44
                        implicitHeight: 34
                        
                        contentItem: Text {
                            text: window.visibility === Window.Maximized ? "⧉" : "▢"
                            color: maxBtn.hovered ? window.colText : window.topBarFg
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: maxBtn.down ? "#33415560" : (maxBtn.hovered ? "#33415530" : "transparent")
                        }
                        
                        onClicked: {
                            if (window.visibility === Window.Maximized) {
                                window.showNormal()
                            } else {
                                window.showMaximized()
                            }
                        }
                    }

                    Button {
                        id: closeBtn
                        implicitWidth: 44
                        implicitHeight: 34
                        
                        contentItem: Text {
                            text: "✕"
                            color: closeBtn.hovered ? "white" : window.topBarFg
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: closeBtn.down ? "#dc2626" : (closeBtn.hovered ? "#ef4444" : "transparent")
                        }
                        
                        onClicked: window.close()
                    }
                }
            }
        }

        StackLayout {
            id: mainStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0
            
            LoginView {
                id: loginView
                opacity: mainStack.currentIndex === 0 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            
            ChatView {
                id: chatView
                opacity: mainStack.currentIndex === 1 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    
    // Frameless window resize borders
    MouseArea {
        width: 6
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeHorCursor
        onPressed: window.startSystemResize(Qt.LeftEdge)
        z: 9999
    }
    MouseArea {
        width: 6
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeHorCursor
        onPressed: window.startSystemResize(Qt.RightEdge)
        z: 9999
    }
    MouseArea {
        height: 6
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        cursorShape: Qt.SizeVerCursor
        onPressed: window.startSystemResize(Qt.TopEdge)
        z: 9999
    }
    MouseArea {
        height: 6
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        cursorShape: Qt.SizeVerCursor
        onPressed: window.startSystemResize(Qt.BottomEdge)
        z: 9999
    }
    MouseArea {
        width: 10
        height: 10
        anchors.left: parent.left
        anchors.top: parent.top
        cursorShape: Qt.SizeFDiagCursor
        onPressed: window.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
        z: 10000
    }
    MouseArea {
        width: 10
        height: 10
        anchors.right: parent.right
        anchors.top: parent.top
        cursorShape: Qt.SizeBDiagCursor
        onPressed: window.startSystemResize(Qt.TopEdge | Qt.RightEdge)
        z: 10000
    }
    MouseArea {
        width: 10
        height: 10
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeBDiagCursor
        onPressed: window.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
        z: 10000
    }
    MouseArea {
        width: 10
        height: 10
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeFDiagCursor
        onPressed: window.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
        z: 10000
    }

    Dialog {
        id: aboutDialog
        anchors.centerIn: parent
        modal: true
        focus: true
        padding: 24
        
        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 2
        }
        
        contentItem: ColumnLayout {
            spacing: 14
            width: 280
            
            Text {
                text: "About Qubber"
                color: window.colText
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignLeft
            }
            
            Image {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                source: "../logo.svg"
                sourceSize: Qt.size(64, 64)
            }
            
            Text {
                text: "Version 1.0.0"
                color: window.colMuted
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "A clean, modern XMPP client built with Qt6 & Python."
                color: window.colText
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Button {
                id: aboutOkBtn
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 100
                implicitHeight: 34
                
                contentItem: Text {
                    text: "OK"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: aboutOkBtn.down ? window.colPrimaryDark : (aboutOkBtn.hovered ? window.colAccent : window.colPrimary)
                    radius: 2
                }
                
                onClicked: aboutDialog.close()
            }
        }
    }

    Dialog {
        id: contactsListPopup
        objectName: "contactsListPopup"
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 360
        height: 500
        
        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 16
        }
        
        header: Rectangle {
            color: "transparent"
            height: 50
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                
                Text {
                    text: "Contacts Roster"
                    color: window.colText
                    font.pixelSize: 15
                    font.bold: true
                }
            }
        }
        
        contentItem: ColumnLayout {
            spacing: 12
            
            // Search Input Field inside the Popup
            TextField {
                id: popupSearchInput
                Layout.fillWidth: true
                placeholderText: "Search contacts..."
                placeholderTextColor: "#4b5563"
                color: window.colText
                font.pixelSize: 13
                selectByMouse: true
                leftPadding: 10
                rightPadding: 10
                topPadding: 8
                bottomPadding: 8
                
                background: Rectangle {
                    color: popupSearchInput.activeFocus ? "#0b0f19" : window.colInputBg
                    border.color: popupSearchInput.activeFocus ? window.colPrimary : window.colBorder
                    border.width: 1
                    radius: 8
                }
            }
            
            // Contacts ListView
            ListView {
                id: popupRosterList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: rosterModel
                
                // Expose filter text to delegates (matched with search input)
                property string filterText: popupSearchInput.text.toLowerCase().trim()
                
                delegate: ContactDelegate {}
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
        
        footer: Rectangle {
            color: "transparent"
            height: 54
            
            Button {
                id: closePopupBtn
                anchors.centerIn: parent
                width: 100
                implicitHeight: 32
                
                contentItem: Text {
                    text: "Close"
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                
                background: Rectangle {
                    color: closePopupBtn.down ? window.colPrimaryDark : (closePopupBtn.hovered ? window.colAccent : window.colPrimary)
                    radius: 8
                }
                
                onClicked: contactsListPopup.close()
            }
        }
        
        onClosed: {
            popupSearchInput.text = ""
        }
    }

    Dialog {
        id: changeStatusPopup
        objectName: "changeStatusPopup"
        anchors.centerIn: parent
        modal: true
        focus: true
        width: 380
        height: 340
        
        property string selfStatus: "available"
        
        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 16
        }
        
        header: Rectangle {
            color: "transparent"
            height: 50
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                
                Text {
                    text: "Change Presence Status"
                    color: window.colText
                    font.pixelSize: 15
                    font.bold: true
                }
            }
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            
            // Presence Selector Buttons
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    text: "Presence Status"
                    color: window.colText
                    font.pixelSize: 13
                    font.bold: true
                }
                
                RowLayout {
                    spacing: 12
                    Layout.fillWidth: true
                    
                    // Available (Online)
                    Rectangle {
                        id: statusOnlineRect
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: changeStatusPopup.selfStatus === "available" ? "#10b98115" : window.colInputBg
                        border.color: changeStatusPopup.selfStatus === "available" ? window.colOnline : window.colBorder
                        border.width: 1.5
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: window.colOnline }
                            Text { text: "Online"; color: window.colText; font.pixelSize: 12; font.bold: true }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                changeStatusPopup.selfStatus = "available"
                            }
                        }
                    }
                    
                    // Away
                    Rectangle {
                        id: statusAwayRect
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: changeStatusPopup.selfStatus === "away" ? "#f59e0b15" : window.colInputBg
                        border.color: changeStatusPopup.selfStatus === "away" ? window.colAway : window.colBorder
                        border.width: 1.5
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: window.colAway }
                            Text { text: "Away"; color: window.colText; font.pixelSize: 12; font.bold: true }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                changeStatusPopup.selfStatus = "away"
                            }
                        }
                    }
                    
                    // Do Not Disturb (DND)
                    Rectangle {
                        id: statusDndRect
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: changeStatusPopup.selfStatus === "dnd" ? "#ef444415" : window.colInputBg
                        border.color: changeStatusPopup.selfStatus === "dnd" ? window.colDnd : window.colBorder
                        border.width: 1.5
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: window.colDnd }
                            Text { text: "Busy"; color: window.colText; font.pixelSize: 12; font.bold: true }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                changeStatusPopup.selfStatus = "dnd"
                            }
                        }
                    }
                }
            }
            
            // Status Message Input
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                
                Text {
                    text: "Status Message"
                    color: window.colText
                    font.pixelSize: 13
                    font.bold: true
                }
                
                TextField {
                    id: popupStatusMsgInput
                    placeholderText: "Set status message..."
                    placeholderTextColor: "#4b5563"
                    color: window.colText
                    Layout.fillWidth: true
                    font.pixelSize: 13
                    selectByMouse: true
                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 8
                    bottomPadding: 8
                    
                    background: Rectangle {
                        color: popupStatusMsgInput.activeFocus ? "#0b0f19" : window.colInputBg
                        border.color: popupStatusMsgInput.activeFocus ? window.colPrimary : window.colBorder
                        border.width: 1.5
                        radius: 8
                    }
                }
            }
        }
        
        footer: Rectangle {
            color: "transparent"
            height: 54
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12
                
                Button {
                    id: cancelStatusBtn
                    Layout.fillWidth: true
                    implicitHeight: 32
                    
                    contentItem: Text {
                        text: "Cancel"
                        color: window.colMuted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: "transparent"
                        border.color: window.colBorder
                        border.width: 1
                        radius: 8
                    }
                    
                    onClicked: changeStatusPopup.close()
                }
                
                Button {
                    id: saveStatusBtn
                    Layout.fillWidth: true
                    implicitHeight: 32
                    
                    contentItem: Text {
                        text: "Save"
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }
                    
                    background: Rectangle {
                        color: saveStatusBtn.down ? window.colPrimaryDark : (saveStatusBtn.hovered ? window.colAccent : window.colPrimary)
                        radius: 8
                    }
                    
                    onClicked: {
                        xmppBackend.changePresence(changeStatusPopup.selfStatus, popupStatusMsgInput.text.trim())
                        changeStatusPopup.close()
                    }
                }
            }
        }
    }

    AddContactDialog {
        id: addContactDialog
    }

    SubscriptionDialog {
        id: subscriptionDialog
    }
}
}