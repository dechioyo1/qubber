import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog
    anchors.centerIn: parent
    modal: true
    focus: true
    
    background: Rectangle {
        color: window.colCard
        border.color: window.colBorder
        border.width: 1
        radius: 16
    }
    
    header: Rectangle {
        color: "transparent"
        height: 54
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            
            Text {
                text: "Add Contact"
                color: window.colText
                font.pixelSize: 16
                font.bold: true
            }
        }
    }
    
    contentItem: ColumnLayout {
        spacing: 16
        width: 340
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            Text {
                text: "JID (Jabber ID)"
                color: window.colText
                font.pixelSize: 13
                font.bold: true
            }
            
            TextField {
                id: jidInput
                placeholderText: "friend@domain.com"
                color: window.colText
                placeholderTextColor: "#4b5563"
                Layout.fillWidth: true
                selectByMouse: true
                font.pixelSize: 14
                leftPadding: 10
                rightPadding: 10
                topPadding: 8
                bottomPadding: 8
                
                background: Rectangle {
                    color: jidInput.activeFocus ? "#0b0f19" : window.colInputBg
                    border.color: jidInput.activeFocus ? window.colPrimary : window.colBorder
                    border.width: 1
                    radius: 8
                }
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            Text {
                text: "Nickname (Optional)"
                color: window.colText
                font.pixelSize: 13
                font.bold: true
            }
            
            TextField {
                id: nickInput
                placeholderText: "Display Name"
                color: window.colText
                placeholderTextColor: "#4b5563"
                Layout.fillWidth: true
                selectByMouse: true
                font.pixelSize: 14
                leftPadding: 10
                rightPadding: 10
                topPadding: 8
                bottomPadding: 8
                
                background: Rectangle {
                    color: nickInput.activeFocus ? "#0b0f19" : window.colInputBg
                    border.color: nickInput.activeFocus ? window.colPrimary : window.colBorder
                    border.width: 1
                    radius: 8
                }
            }
        }
    }
    
    footer: Rectangle {
        color: "transparent"
        height: 64
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12
            
            Button {
                id: cancelBtn
                Layout.fillWidth: true
                implicitHeight: 38
                
                contentItem: Text {
                    text: "Cancel"
                    color: window.colMuted
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: cancelBtn.down ? "#33415540" : (cancelBtn.hovered ? "#33415520" : "transparent")
                    border.color: window.colBorder
                    border.width: 1
                    radius: 8
                }
                
                onClicked: dialog.reject()
            }
            
            Button {
                id: addBtn
                Layout.fillWidth: true
                implicitHeight: 38
                enabled: jidInput.text.trim() !== ""
                
                contentItem: Text {
                    text: "Add"
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                
                background: Rectangle {
                    color: addBtn.down ? window.colPrimaryDark : (addBtn.hovered ? window.colAccent : window.colPrimary)
                    radius: 8
                    opacity: addBtn.enabled ? 1.0 : 0.5
                }
                
                onClicked: {
                    xmppBackend.addContact(jidInput.text.trim(), nickInput.text.trim())
                    dialog.accept()
                }
            }
        }
    }
    
    onClosed: {
        jidInput.text = ""
        nickInput.text = ""
    }
}
