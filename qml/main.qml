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
    property bool alwaysOnTop: false
    flags: Qt.Window | Qt.FramelessWindowHint | (alwaysOnTop ? Qt.WindowStaysOnTopHint : Qt.Widget)
    
    color: window.colBg
    
    readonly property bool isNormalWindow: window.visibility !== Window.Maximized && window.visibility !== Window.FullScreen
    readonly property bool isMenuBarActive: qubberMenu.opened || contactsMenu.opened || accountMenu.opened

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
                    property bool preventOpen: false
                    
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
                            color: qubberBtn.hovered ? window.colPrimary : window.colText
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }
                    
                    hoverEnabled: true
                    onHoveredChanged: {
                        if (hovered && window.isMenuBarActive) {
                            contactsMenu.close()
                            accountMenu.close()
                            qubberMenu.open()
                        }
                    }
                    
                     MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                systemWindowMenu.open()
                            } else {
                                if (qubberMenu.opened) {
                                    qubberMenu.close()
                                } else if (!qubberBtn.preventOpen) {
                                    qubberMenu.open()
                                }
                                qubberBtn.preventOpen = false
                            }
                        }
                    }

                    Popup {
                        id: systemWindowMenu
                        y: parent.height + 4
                        x: 0
                        width: 180
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
                                id: sysRestoreBtn
                                Layout.fillWidth: true
                                implicitHeight: 32
                                enabled: window.visibility === Window.Maximized
                                
                                contentItem: Text {
                                    text: "Restore"
                                    color: sysRestoreBtn.enabled ? (sysRestoreBtn.hovered ? "white" : window.colText) : window.colMuted
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: sysRestoreBtn.hovered && sysRestoreBtn.enabled ? window.colPrimary : "transparent"
                                    radius: 6
                                }
                                
                                onClicked: {
                                    systemWindowMenu.close()
                                    window.showNormal()
                                }
                            }
                            
                            Button {
                                id: sysMoveBtn
                                Layout.fillWidth: true
                                implicitHeight: 32
                                
                                contentItem: Text {
                                    text: "Move"
                                    color: sysMoveBtn.hovered ? "white" : window.colText
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: sysMoveBtn.hovered ? window.colPrimary : "transparent"
                                    radius: 6
                                }
                                
                                onClicked: {
                                    systemWindowMenu.close()
                                    window.startSystemMove()
                                }
                            }
                            
                            Button {
                                id: sysMinimizeBtn
                                Layout.fillWidth: true
                                implicitHeight: 32
                                
                                contentItem: Text {
                                    text: "Minimize"
                                    color: sysMinimizeBtn.hovered ? "white" : window.colText
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: sysMinimizeBtn.hovered ? window.colPrimary : "transparent"
                                    radius: 6
                                }
                                
                                onClicked: {
                                    systemWindowMenu.close()
                                    window.showMinimized()
                                }
                            }
                            
                            Button {
                                id: sysMaximizeBtn
                                Layout.fillWidth: true
                                implicitHeight: 32
                                enabled: window.visibility !== Window.Maximized
                                
                                contentItem: Text {
                                    text: "Maximize"
                                    color: sysMaximizeBtn.enabled ? (sysMaximizeBtn.hovered ? "white" : window.colText) : window.colMuted
                                    font.pixelSize: 13
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: sysMaximizeBtn.hovered && sysMaximizeBtn.enabled ? window.colPrimary : "transparent"
                                    radius: 6
                                }
                                
                                onClicked: {
                                    systemWindowMenu.close()
                                    window.showMaximized()
                                }
                            }
                            
                            Button {
                                id: sysAlwaysOnTopBtn
                                Layout.fillWidth: true
                                implicitHeight: 32
                                
                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8
                                    Text {
                                        text: "Always on Top"
                                        color: sysAlwaysOnTopBtn.hovered ? "white" : window.colText
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text {
                                        text: window.alwaysOnTop ? "✓" : ""
                                        color: sysAlwaysOnTopBtn.hovered ? "white" : window.colPrimary
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                
                                background: Rectangle {
                                    color: sysAlwaysOnTopBtn.hovered ? window.colPrimary : "transparent"
                                    radius: 6
                                }
                                
                                onClicked: {
                                    systemWindowMenu.close()
                                    window.alwaysOnTop = !window.alwaysOnTop
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: window.colBorder
                            }
                            
                            Button {
                                id: sysCloseBtn
                                Layout.fillWidth: true
                                implicitHeight: 32
                                
                                contentItem: Text {
                                    text: "Close"
                                    color: sysCloseBtn.hovered ? "white" : window.colText
                                    font.pixelSize: 13
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: sysCloseBtn.hovered ? "#ef4444" : "transparent"
                                    radius: 6
                                }
                                
                                onClicked: {
                                    systemWindowMenu.close()
                                    window.close()
                                }
                            }
                        }
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
                        
                        onClosed: {
                            if (qubberBtn.hovered) {
                                qubberBtn.preventOpen = true
                                menuDelayTimer.start()
                            }
                        }
                        
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
                        property bool preventOpen: false
                        
                        contentItem: Text {
                            text: "Contacts"
                            color: contactsBtn.hovered ? window.colPrimary : window.colText
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: contactsBtn.hovered ? "#33415530" : "transparent"
                            radius: 6
                        }
                        
                        hoverEnabled: true
                        onHoveredChanged: {
                            if (hovered && window.isMenuBarActive) {
                                qubberMenu.close()
                                accountMenu.close()
                                contactsMenu.open()
                            }
                        }
                        
                        onClicked: {
                            if (contactsMenu.opened) {
                                contactsMenu.close()
                            } else if (!preventOpen) {
                                contactsMenu.open()
                            }
                            preventOpen = false
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
                            
                            onClosed: {
                                if (contactsBtn.hovered) {
                                    contactsBtn.preventOpen = true
                                    menuDelayTimer.start()
                                }
                            }
                            
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
                        property bool preventOpen: false
                        
                        contentItem: Text {
                            text: xmppBackend.myJid !== "" ? xmppBackend.myJid : "Account"
                            color: accountBtn.hovered ? window.colPrimary : window.colText
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: accountBtn.hovered ? "#33415530" : "transparent"
                            radius: 6
                        }
                        
                        hoverEnabled: true
                        onHoveredChanged: {
                            if (hovered && window.isMenuBarActive) {
                                qubberMenu.close()
                                contactsMenu.close()
                                accountMenu.open()
                            }
                        }
                        
                        onClicked: {
                            if (accountMenu.opened) {
                                accountMenu.close()
                            } else if (!preventOpen) {
                                accountMenu.open()
                            }
                            preventOpen = false
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
                            
                            onClosed: {
                                if (accountBtn.hovered) {
                                    accountBtn.preventOpen = true
                                    menuDelayTimer.start()
                                }
                            }
                            
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
                            color: minBtn.hovered ? window.colPrimary : window.colText
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
                            color: maxBtn.hovered ? window.colPrimary : window.colText
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
                            color: closeBtn.hovered ? "white" : window.colText
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
        padding: 24
        
        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 2
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            
            Text {
                text: "Contacts Roster"
                color: window.colText
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignLeft
            }
            
            TextField {
                id: popupSearchInput
                Layout.fillWidth: true
                placeholderText: "Search contacts..."
                placeholderTextColor: "#4b5563"
                color: window.colText
                font.pixelSize: 14
                selectByMouse: true
                leftPadding: 10
                rightPadding: 10
                topPadding: 8
                bottomPadding: 8
                
                background: Rectangle {
                    color: popupSearchInput.activeFocus ? "#0b0f19" : window.colInputBg
                    border.color: popupSearchInput.activeFocus ? window.colPrimary : window.colBorder
                    border.width: 1
                    radius: 2
                }
            }
            
            ListView {
                id: popupRosterList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: rosterModel
                
                property string filterText: popupSearchInput.text.toLowerCase().trim()
                
                delegate: ContactDelegate {}
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
            
            Button {
                id: closePopupBtn
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 100
                implicitHeight: 34
                
                contentItem: Text {
                    text: "Close"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: closePopupBtn.down ? window.colPrimaryDark : (closePopupBtn.hovered ? window.colAccent : window.colPrimary)
                    radius: 2
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
        padding: 24
        
        property string selfStatus: "available"
        
        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 2
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            
            Text {
                text: "Change Presence Status"
                color: window.colText
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignLeft
            }
            
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
                        radius: 2
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
                        radius: 2
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
                        radius: 2
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
                        radius: 2
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.topMargin: 8
                
                Button {
                    id: cancelStatusBtn
                    Layout.fillWidth: true
                    implicitHeight: 36
                    
                    contentItem: Text {
                        text: "Cancel"
                        color: window.colText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: "transparent"
                        border.color: window.colBorder
                        border.width: 1
                        radius: 2
                    }
                    
                    onClicked: changeStatusPopup.close()
                }
                
                Button {
                    id: saveStatusBtn
                    Layout.fillWidth: true
                    implicitHeight: 36
                    
                    contentItem: Text {
                        text: "Save"
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }
                    
                    background: Rectangle {
                        color: saveStatusBtn.down ? window.colPrimaryDark : (saveStatusBtn.hovered ? window.colAccent : window.colPrimary)
                        radius: 2
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
    
    Timer {
        id: menuDelayTimer
        interval: 150
        onTriggered: {
            qubberBtn.preventOpen = false
            contactsBtn.preventOpen = false
            accountBtn.preventOpen = false
        }
    }
}
