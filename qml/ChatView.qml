import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    objectName: "chatView"
    
    property string selfStatus: "available"
    property string hoveredStatus: ""
    property string filterText: searchInput.text.toLowerCase().trim()
    property bool sidebarCollapsed: false

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
            SplitView.preferredWidth: 320
            SplitView.minimumWidth: 260
            SplitView.maximumWidth: 380
            color: "#111322" // Deep dark sidebar background
            
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
                                root.sidebarCollapsed = true
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
                    
                    // Expose filterText to delegates
                    property string filterText: root.filterText
                    
                    delegate: ContactDelegate {}
                    
                    // Spacer at the bottom
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
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
                visible: xmppBackend.activeChatJid === ""
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
            
            // Active Chat Interface
            ColumnLayout {
                anchors.fill: parent
                visible: xmppBackend.activeChatJid !== ""
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
                                root.sidebarCollapsed = false
                            }
                        }
                        
                        Text {
                            text: xmppBackend.activeChatJid
                            color: window.colText
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
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
                    
                    // Align messages to the bottom when history is short
                    topMargin: Math.max(0, height - contentHeight)
                    Behavior on topMargin { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                    
                    // Auto-scroll on new message (Qt.callLater ensures new delegates are loaded/positioned before scrolling)
                    onCountChanged: {
                        Qt.callLater(chatHistoryView.positionViewAtEnd)
                    }
                }
                
                // Message Input Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    color: "#16192b"
                    
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: window.colBorder
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12
                        
                        Button {
                            id: attachBtn
                            implicitWidth: 32
                            implicitHeight: 32
                            
                            contentItem: Image {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: attachBtn.hovered ? "icons/attach_file_white.svg" : "icons/attach_file_muted.svg"
                                sourceSize: Qt.size(20, 20)
                            }
                            
                            background: Rectangle {
                                color: attachBtn.hovered ? "#33415520" : "transparent"
                                radius: 16
                            }
                            
                            onClicked: attachMenu.open()
                            
                            Popup {
                                id: attachMenu
                                y: -attachMenu.height - 4
                                x: 0
                                width: 120
                                padding: 6
                                modal: true
                                focus: true
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                
                                background: Rectangle {
                                    color: "#1e293b"
                                    border.color: window.colBorder
                                    radius: 8
                                }
                                
                                contentItem: ColumnLayout {
                                    spacing: 4
                                    
                                    Button {
                                        id: attachImageBtn
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        
                                        contentItem: RowLayout {
                                            spacing: 8
                                            Image {
                                                Layout.leftMargin: 8
                                                width: 16
                                                height: 16
                                                source: attachImageBtn.hovered ? "icons/image_white.svg" : "icons/image_muted.svg"
                                                sourceSize: Qt.size(16, 16)
                                            }
                                            Text {
                                                text: "Image"
                                                color: attachImageBtn.hovered ? "white" : window.colText
                                                font.pixelSize: 12
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            color: attachImageBtn.hovered ? window.colPrimary : "transparent"
                                            radius: 6
                                        }
                                        
                                        onClicked: {
                                            attachMenu.close()
                                        }
                                    }
                                    
                                    Button {
                                        id: attachFileBtn
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        
                                        contentItem: RowLayout {
                                            spacing: 8
                                            Image {
                                                Layout.leftMargin: 8
                                                width: 16
                                                height: 16
                                                source: attachFileBtn.hovered ? "icons/description_white.svg" : "icons/description_muted.svg"
                                                sourceSize: Qt.size(16, 16)
                                            }
                                            Text {
                                                text: "File"
                                                color: attachFileBtn.hovered ? "white" : window.colText
                                                font.pixelSize: 12
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            color: attachFileBtn.hovered ? window.colPrimary : "transparent"
                                            radius: 6
                                        }
                                        
                                        onClicked: {
                                            attachMenu.close()
                                        }
                                    }
                                    
                                    Button {
                                        id: attachLocationBtn
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        
                                        contentItem: RowLayout {
                                            spacing: 8
                                            Image {
                                                Layout.leftMargin: 8
                                                width: 16
                                                height: 16
                                                source: attachLocationBtn.hovered ? "icons/location_on_white.svg" : "icons/location_on_muted.svg"
                                                sourceSize: Qt.size(16, 16)
                                            }
                                            Text {
                                                text: "Location"
                                                color: attachLocationBtn.hovered ? "white" : window.colText
                                                font.pixelSize: 12
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            color: attachLocationBtn.hovered ? window.colPrimary : "transparent"
                                            radius: 6
                                        }
                                        
                                        onClicked: {
                                            attachMenu.close()
                                        }
                                    }
                                }
                            }
                        }
                        
                        TextField {
                            id: messageInput
                            placeholderText: "Type a message..."
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
                            
                            onAccepted: {
                                if (text.trim() !== "") {
                                    xmppBackend.sendMessage(text.trim())
                                    text = ""
                                }
                            }
                        }
                        
                        Button {
                            id: sendBtn
                            implicitWidth: 32
                            implicitHeight: 32
                            visible: messageInput.text.trim() !== ""
                            
                            contentItem: Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: "icons/send_primary.svg"
                                sourceSize: Qt.size(16, 16)
                            }
                            
                            background: Rectangle {
                                radius: 16
                                color: sendBtn.down ? "#1d4ed815" : "transparent"
                                border.color: window.colPrimary
                                border.width: 1.5
                            }
                            
                            onClicked: {
                                xmppBackend.sendMessage(messageInput.text.trim())
                                messageInput.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
    
}
