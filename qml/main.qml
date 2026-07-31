import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

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
    readonly property bool isMenuBarActive: contactsMenu.opened || settingsMenu.opened || accountMenu.opened

    // Theme palette bound dynamically to themeManager
    readonly property color colPrimary: themeManager ? themeManager.colPrimary : "#2563eb"
    readonly property color colPrimaryDark: themeManager ? themeManager.colPrimaryDark : "#1d4ed8"
    readonly property color colAccent: themeManager ? themeManager.colAccent : "#7c3aed"
    readonly property color colBg: themeManager ? themeManager.colBg : "#ffffff"
    readonly property color colCard: themeManager ? themeManager.colCard : "#f8fafc"
    readonly property color colText: themeManager ? themeManager.colText : "#0f172a"
    readonly property color colMuted: themeManager ? themeManager.colMuted : "#64748b"
    readonly property color colBorder: themeManager ? themeManager.colBorder : "#e2e8f0"
    readonly property color colInputBg: themeManager ? themeManager.colInputBg : "#f1f5f9"
    readonly property color topBarBg: themeManager ? themeManager.topBarBg : "#f8fafc"
    readonly property color topBarFg: themeManager ? themeManager.topBarFg : "#0f172a"
    readonly property color sidebarBg: themeManager ? themeManager.sidebarBg : "#f8fafc"
    readonly property color sidebarHeaderBg: themeManager ? themeManager.sidebarHeaderBg : "#f1f5f9"
    readonly property color sidebarBgOver: themeManager ? themeManager.sidebarBgOver : "#e2e8f0"
    readonly property color sidebarBgActive: themeManager ? themeManager.sidebarBgActive : "#2563eb"
    readonly property color msgInBg: themeManager ? themeManager.msgInBg : "#f1f5f9"
    readonly property color msgInText: themeManager ? themeManager.msgInText : "#0f172a"
    readonly property color msgOutBg: themeManager ? themeManager.msgOutBg : "#2563eb"
    readonly property color msgOutText: themeManager ? themeManager.msgOutText : "#ffffff"

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



                // Menubar menu items (Status, Contacts, Settings & Account)
                // Visible only when logged in (currentIndex is not 0)
                RowLayout {
                    spacing: 4
                    visible: mainStack.currentIndex !== 0

                    Button {
                        id: statusBtn
                        implicitHeight: 26
                        property bool preventOpen: false
                        
                        contentItem: RowLayout {
                            spacing: 6
                            
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                Layout.alignment: Qt.AlignVCenter
                                color: {
                                    var st = xmppBackend.myStatus;
                                    if (st === "away") return window.colAway;
                                    if (st === "dnd") return window.colDnd;
                                    return window.colOnline;
                                }
                            }
                            
                            Text {
                                text: {
                                    var msg = xmppBackend.myStatusMessage ? xmppBackend.myStatusMessage.trim() : "";
                                    if (msg !== "") {
                                        return msg.length > 10 ? msg.substring(0, 10) + "..." : msg;
                                    }
                                    var st = xmppBackend.myStatus;
                                    if (st === "away") return "Away";
                                    if (st === "dnd") return "Busy";
                                    return "Online";
                                }
                                color: statusBtn.hovered ? window.colPrimary : window.colText
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        
                        background: Rectangle {
                            color: statusBtn.hovered ? "#33415530" : "transparent"
                            radius: 6
                        }
                        
                        onClicked: {
                            changeStatusPopup.open()
                        }
                    }

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
                                settingsMenu.close()
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
                        id: settingsBtn
                        implicitHeight: 26
                        property bool preventOpen: false
                        
                        contentItem: Text {
                            text: "Settings"
                            color: settingsBtn.hovered ? window.colPrimary : window.colText
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            color: settingsBtn.hovered ? "#33415530" : "transparent"
                            radius: 6
                        }
                        
                        hoverEnabled: true
                        onHoveredChanged: {
                            if (hovered && window.isMenuBarActive) {
                                contactsMenu.close()
                                accountMenu.close()
                                settingsMenu.open()
                            }
                        }
                        
                        onClicked: {
                            if (settingsMenu.opened) {
                                settingsMenu.close()
                            } else if (!preventOpen) {
                                settingsMenu.open()
                            }
                            preventOpen = false
                        }

                        Popup {
                            id: settingsMenu
                            y: parent.height + 4
                            x: 0
                            width: 160
                            padding: 6
                            modal: false
                            focus: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            
                            onClosed: {
                                if (settingsBtn.hovered) {
                                    settingsBtn.preventOpen = true
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
                                    id: themeMenuBtn
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    
                                    contentItem: Text {
                                        text: "Theme..."
                                        color: themeMenuBtn.hovered ? "white" : window.colText
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    
                                    background: Rectangle {
                                        color: themeMenuBtn.hovered ? window.colPrimary : "transparent"
                                        radius: 6
                                    }
                                    
                                    onClicked: {
                                        settingsMenu.close()
                                        themeDialog.open()
                                    }
                                }

                                Button {
                                    id: encryptionMenuBtn
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    
                                    contentItem: Text {
                                        text: "Encryption (OMEMO)..."
                                        color: encryptionMenuBtn.hovered ? "white" : window.colText
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    
                                    background: Rectangle {
                                        color: encryptionMenuBtn.hovered ? window.colPrimary : "transparent"
                                        radius: 6
                                    }
                                    
                                    onClicked: {
                                        settingsMenu.close()
                                        encryptionDialog.open()
                                    }
                                }

                                Button {
                                    id: aboutSettingsMenuBtn
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    
                                    contentItem: Text {
                                        text: "About Qubber"
                                        color: aboutSettingsMenuBtn.hovered ? "white" : window.colText
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    
                                    background: Rectangle {
                                        color: aboutSettingsMenuBtn.hovered ? window.colPrimary : "transparent"
                                        radius: 6
                                    }
                                    
                                    onClicked: {
                                        settingsMenu.close()
                                        aboutDialog.open()
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
                                contactsMenu.close()
                                settingsMenu.close()
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
        id: themeDialog
        anchors.centerIn: parent
        modal: true
        focus: true
        padding: 24
        
        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 8
        }
        
        contentItem: ColumnLayout {
            spacing: 14
            width: 320
            
            Text {
                text: "Theme Settings"
                color: window.colText
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignLeft
            }
            
            Text {
                text: "Select Theme Preset:"
                color: window.colMuted
                font.pixelSize: 12
            }
            
            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                
                Button {
                    id: lightThemeBtn
                    Layout.fillWidth: true
                    implicitHeight: 38
                    
                    contentItem: Text {
                        text: "☀️ Light"
                        color: (themeManager && themeManager.currentTheme === "light") ? "white" : window.colText
                        font.bold: true
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: (themeManager && themeManager.currentTheme === "light") 
                            ? window.colPrimary 
                            : (lightThemeBtn.hovered ? "#33415530" : window.colInputBg)
                        border.color: window.colBorder
                        radius: 6
                    }
                    
                    onClicked: {
                        if (themeManager) themeManager.selectTheme("light")
                    }
                }

                Button {
                    id: darkThemeBtn
                    Layout.fillWidth: true
                    implicitHeight: 38
                    
                    contentItem: Text {
                        text: "🌙 Atom One Dark"
                        color: (themeManager && themeManager.currentTheme === "dark") ? "white" : window.colText
                        font.bold: true
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: (themeManager && themeManager.currentTheme === "dark") 
                            ? window.colPrimary 
                            : (darkThemeBtn.hovered ? "#33415530" : window.colInputBg)
                        border.color: window.colBorder
                        radius: 6
                    }
                    
                    onClicked: {
                        if (themeManager) themeManager.selectTheme("dark")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: window.colBorder
            }
            
            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                
                Button {
                    id: loadThemeFileBtn
                    Layout.fillWidth: true
                    implicitHeight: 36
                    
                    contentItem: Text {
                        text: "Load Theme File..."
                        color: window.colText
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: loadThemeFileBtn.hovered ? "#33415540" : "transparent"
                        border.color: window.colBorder
                        radius: 6
                    }
                    
                    onClicked: {
                        themeFileDialog.open()
                    }
                }
                
                Button {
                    id: reloadThemeBtn
                    Layout.fillWidth: true
                    implicitHeight: 36
                    
                    contentItem: Text {
                        text: "Reload Current"
                        color: window.colText
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: reloadThemeBtn.hovered ? "#33415540" : "transparent"
                        border.color: window.colBorder
                        radius: 6
                    }
                    
                    onClicked: {
                        if (themeManager) themeManager.reloadTheme()
                    }
                }
            }
            
            Button {
                id: closeThemeDialogBtn
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 100
                implicitHeight: 34
                
                contentItem: Text {
                    text: "Close"
                    color: window.colText
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: "transparent"
                    border.color: window.colBorder
                    radius: 6
                }
                
                onClicked: themeDialog.close()
            }
        }
    }
    
    Dialog {
        id: encryptionDialog
        anchors.centerIn: parent
        modal: true
        focus: true
        padding: 24
        
        background: Rectangle {
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            radius: 8
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            width: 380
            
            RowLayout {
                spacing: 10
                Image {
                    width: 24
                    height: 24
                    source: "icons/lock_primary.svg"
                    sourceSize: Qt.size(24, 24)
                }
                Text {
                    text: "OMEMO Encryption Settings"
                    color: window.colText
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                }
            }
            
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                
                Text {
                    text: "Device ID"
                    color: window.colMuted
                    font.pixelSize: 12
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: window.colInputBg
                    border.color: window.colBorder
                    radius: 6
                    
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        text: (xmppBackend && xmppBackend.omemoDeviceId) ? xmppBackend.omemoDeviceId.toString() : "N/A"
                        color: window.colText
                        font.pixelSize: 13
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
            
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                
                Text {
                    text: "Your OMEMO Identity Fingerprint"
                    color: window.colMuted
                    font.pixelSize: 12
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    color: window.colInputBg
                    border.color: window.colBorder
                    radius: 6
                    
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        text: (xmppBackend && xmppBackend.omemoFingerprint) ? xmppBackend.omemoFingerprint : "N/A"
                        color: window.colAccent
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Monospace"
                        wrapMode: Text.Wrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
            
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                
                Text {
                    text: "OMEMO Key Storage Database"
                    color: window.colMuted
                    font.pixelSize: 12
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: window.colInputBg
                    border.color: window.colBorder
                    radius: 6
                    
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        text: xmppBackend ? xmppBackend.getOmemoDbPath() : "N/A"
                        color: window.colText
                        font.pixelSize: 11
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideMiddle
                    }
                }
            }
            
            RowLayout {
                spacing: 12
                Layout.alignment: Qt.AlignRight
                
                Button {
                    id: regenKeysBtn
                    implicitHeight: 36
                    implicitWidth: 140
                    
                    contentItem: Text {
                        text: "Regenerate Keys"
                        color: window.colText
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: regenKeysBtn.hovered ? "#33415540" : "transparent"
                        border.color: window.colBorder
                        radius: 6
                    }
                    
                    onClicked: {
                        if (xmppBackend) xmppBackend.regenerateOmemoKeys()
                    }
                }
                
                Button {
                    id: closeEncDialogBtn
                    implicitHeight: 36
                    implicitWidth: 90
                    
                    contentItem: Text {
                        text: "Done"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: closeEncDialogBtn.down ? window.colPrimaryDark : (closeEncDialogBtn.hovered ? window.colAccent : window.colPrimary)
                        radius: 6
                    }
                    
                    onClicked: encryptionDialog.close()
                }
            }
        }
    }
    
    FileDialog {
        id: themeFileDialog
        title: "Select Theme File"
        nameFilters: ["Theme files (*.tdesktop-theme *.palette *.txt)", "All files (*)"]
        onAccepted: {
            themeManager.loadThemeFromFile(selectedFile.toString())
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
            statusBtn.preventOpen = false
            contactsBtn.preventOpen = false
            settingsBtn.preventOpen = false
            accountBtn.preventOpen = false
        }
    }
}
