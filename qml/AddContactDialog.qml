import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog
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
        spacing: 16
        width: 320
        
        Text {
            text: "Add Contact"
            color: window.colText
            font.pixelSize: 18
            font.bold: true
            Layout.alignment: Qt.AlignLeft
        }
        
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
                    radius: 2
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
                    radius: 2
                }
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Layout.topMargin: 8
            
            Button {
                id: cancelBtn
                Layout.fillWidth: true
                implicitHeight: 36
                
                contentItem: Text {
                    text: "Cancel"
                    color: window.colText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                background: Rectangle {
                    color: cancelBtn.down ? "#33415540" : (cancelBtn.hovered ? "#33415520" : "transparent")
                    border.color: window.colBorder
                    border.width: 1
                    radius: 2
                }
                
                onClicked: dialog.reject()
            }
            
            Button {
                id: addBtn
                Layout.fillWidth: true
                implicitHeight: 36
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
                    radius: 2
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
