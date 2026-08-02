import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    objectName: "loginView"
    
    property bool showAdvanced: false

    ColumnLayout {
        anchors.centerIn: parent
        width: 440
        spacing: 24
        
        // Header Logo
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            
            Rectangle {
                width: 72
                height: 72
                radius: 2
                Layout.alignment: Qt.AlignHCenter
                color: window.colPrimary
                
                Image {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    source: "../logo.svg"
                    sourceSize: Qt.size(50, 50)
                }
                
                scale: 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.scale = 1.06
                    onExited: parent.scale = 1.0
                }
            }
            
            Text {
                text: "Sign in to Qubber"
                color: window.colText
                font.pixelSize: 26
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "A clean, modern XMPP client built with Qt6 & Python"
                color: window.colMuted
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter
            }
        }
        
        // Card Container
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: formLayout.implicitHeight + 48
            radius: 2
            color: window.colCard
            border.color: window.colBorder
            border.width: 1
            
            ColumnLayout {
                id: formLayout
                anchors.fill: parent
                anchors.margins: 28
                spacing: 18
                
                // Status Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    color: "#ef444415"
                    border.color: "#f87171"
                    border.width: 1
                    radius: 2
                    visible: statusLabel.text !== "Disconnected" && statusLabel.text !== ""
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8
                        
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: {
                                var s = statusLabel.text;
                                if (s.indexOf("Connecting") !== -1) return window.colAway;
                                if (s.indexOf("failed") !== -1 || s.indexOf("Error") !== -1 || s.indexOf("Authentication") !== -1) return window.colDnd;
                                return window.colOffline;
                            }
                            
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
                            }
                        }
                        
                        Text {
                            id: statusLabel
                            text: xmppBackend ? xmppBackend.connectionStatus : ""
                            color: window.colText
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
                
                // JID Field
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Text {
                        text: "Jabber ID (JID)"
                        color: window.colText
                        font.pixelSize: 13
                        font.bold: true
                    }
                    
                    TextField {
                        id: jidInput
                        placeholderText: "e.g. user@xmpp.jp"
                        color: window.colText
                        placeholderTextColor: "#4b5563"
                        Layout.fillWidth: true
                        selectByMouse: true
                        font.pixelSize: 14
                        leftPadding: 12
                        rightPadding: 12
                        topPadding: 10
                        bottomPadding: 10
                        
                        background: Rectangle {
                            color: jidInput.activeFocus ? "#0b0f19" : window.colInputBg
                            border.color: jidInput.activeFocus ? window.colPrimary : window.colBorder
                            border.width: 1.5
                            radius: 2
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
                
                // Password Field
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Text {
                        text: "Password"
                        color: window.colText
                        font.pixelSize: 13
                        font.bold: true
                    }
                    
                    TextField {
                        id: passwordInput
                        placeholderText: "••••••••"
                        placeholderTextColor: "#4b5563"
                        echoMode: TextInput.Password
                        color: window.colText
                        Layout.fillWidth: true
                        selectByMouse: true
                        font.pixelSize: 14
                        leftPadding: 12
                        rightPadding: 12
                        topPadding: 10
                        bottomPadding: 10
                        
                        background: Rectangle {
                            color: passwordInput.activeFocus ? "#0b0f19" : window.colInputBg
                            border.color: passwordInput.activeFocus ? window.colPrimary : window.colBorder
                            border.width: 1.5
                            radius: 2
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
                
                // Remember Password Checkbox
                CheckBox {
                    id: rememberMeCheckbox
                    text: "Remember password"
                    Layout.fillWidth: true
                    
                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 2
                        color: rememberMeCheckbox.checked ? "transparent" : window.colInputBg
                        border.color: rememberMeCheckbox.checked ? window.colPrimary : window.colBorder
                        border.width: 1.5
                        
                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: 2
                            color: window.colPrimary
                            visible: rememberMeCheckbox.checked
                        }
                    }
                    
                    contentItem: Text {
                        text: rememberMeCheckbox.text
                        font.pixelSize: 13
                        color: window.colText
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: rememberMeCheckbox.indicator.width + rememberMeCheckbox.spacing
                    }
                }
                
                // Advanced Toggle Link
                Text {
                    text: root.showAdvanced ? "▼ Collapse advanced connection settings" : "▶ Show advanced connection settings"
                    color: window.colMuted
                    font.pixelSize: 12
                    font.bold: true
                    Layout.alignment: Qt.AlignLeft
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showAdvanced = !root.showAdvanced
                    }
                }
                
                // Advanced Fields
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.showAdvanced
                    spacing: 12
                    
                    RowLayout {
                        spacing: 12
                        Layout.fillWidth: true
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            
                            Text {
                                text: "Custom Server Host"
                                color: window.colText
                                font.pixelSize: 12
                            }
                            
                            TextField {
                                id: hostInput
                                placeholderText: "Optional host address"
                                color: window.colText
                                placeholderTextColor: "#4b5563"
                                Layout.fillWidth: true
                                selectByMouse: true
                                font.pixelSize: 13
                                leftPadding: 10
                                rightPadding: 10
                                topPadding: 8
                                bottomPadding: 8
                                background: Rectangle {
                                    color: hostInput.activeFocus ? "#0b0f19" : window.colInputBg
                                    border.color: hostInput.activeFocus ? window.colPrimary : window.colBorder
                                    border.width: 1
                                    radius: 2
                                }
                            }
                        }
                        
                        ColumnLayout {
                            width: 100
                            spacing: 6
                            
                            Text {
                                text: "Port"
                                color: window.colText
                                font.pixelSize: 12
                            }
                            
                            TextField {
                                id: portInput
                                placeholderText: "5222"
                                color: window.colText
                                placeholderTextColor: "#4b5563"
                                Layout.fillWidth: true
                                selectByMouse: true
                                font.pixelSize: 13
                                leftPadding: 10
                                rightPadding: 10
                                topPadding: 8
                                bottomPadding: 8
                                background: Rectangle {
                                    color: portInput.activeFocus ? "#0b0f19" : window.colInputBg
                                    border.color: portInput.activeFocus ? window.colPrimary : window.colBorder
                                    border.width: 1
                                    radius: 2
                                }
                            }
                        }
                    }
                }
                
                // Sign In Button
                Button {
                    id: loginButton
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    implicitHeight: 46
                    
                    contentItem: Text {
                        text: (xmppBackend && xmppBackend.connectionStatus === "Connecting...") ? "Connecting..." : "Connect"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        radius: 2
                        color: loginButton.down ? window.colPrimaryDark : window.colPrimary
                        border.color: window.colBorder
                        border.width: loginButton.hovered ? 1 : 0
                        opacity: loginButton.enabled ? 1.0 : 0.6
                    }
                    
                    enabled: jidInput.text.trim() !== "" && passwordInput.text.trim() !== "" && (xmppBackend ? xmppBackend.connectionStatus !== "Connecting..." : true)
                    
                    onClicked: {
                        xmppBackend.login(
                            jidInput.text.trim(), 
                            passwordInput.text.trim(), 
                            hostInput.text.trim(), 
                            portInput.text.trim(),
                            rememberMeCheckbox.checked
                        )
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        jidInput.text = xmppBackend.savedJid
        passwordInput.text = xmppBackend.savedPassword
        hostInput.text = xmppBackend.savedHost
        portInput.text = xmppBackend.savedPort
        rememberMeCheckbox.checked = xmppBackend.savedRememberMe
        
        if (hostInput.text !== "" || portInput.text !== "") {
            root.showAdvanced = true
        }
    }
}
