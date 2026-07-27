import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    objectName: "chatView"
    
    property string selfStatus: "available"
    property string hoveredStatus: ""
    property string filterText: searchInput.text.toLowerCase().trim()

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal
        
        handle: Rectangle {
            implicitWidth: 1
            color: window.colBorder
        }
        
        // Sidebar (Contacts & Settings)
        Rectangle {
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
                
                // Search Input Field
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    color: "transparent"
                    
                    TextField {
                        id: searchInput
                        anchors.fill: parent
                        anchors.margins: 10
                        placeholderText: "Search..."
                        placeholderTextColor: "#4b5563"
                        color: window.colText
                        font.pixelSize: 13
                        selectByMouse: true
                        leftPadding: 10
                        rightPadding: 10
                        
                        background: Rectangle {
                            color: searchInput.activeFocus ? "#0b0f19" : window.colInputBg
                            border.color: searchInput.activeFocus ? window.colPrimary : window.colBorder
                            border.width: 1
                            radius: 8
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
                    
                    Text {
                        anchors.centerIn: parent
                        text: "💬"
                        font.pixelSize: 36
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
                    height: 60
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
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                    
                    // Auto-scroll on new message
                    onCountChanged: {
                        chatHistoryView.positionViewAtEnd()
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
                            
                            contentItem: Text {
                                text: "➔"
                                color: window.colPrimary
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
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
