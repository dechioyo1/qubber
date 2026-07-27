import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog
    anchors.centerIn: parent
    modal: true
    focus: true
    closePolicy: Popup.NoAutoClose
    
    property string requesterJid: ""
    
    background: Rectangle {
        color: window.colCard
        border.color: window.colBorder
        border.width: 1
        radius: 16
        
        // Glow effect
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: window.colPrimary
            border.width: 1
            radius: 16
            opacity: 0.2
        }
    }
    
    header: Rectangle {
        color: "transparent"
        height: 54
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            
            Text {
                text: "Incoming Contact Request"
                color: window.colText
                font.pixelSize: 16
                font.bold: true
            }
        }
    }
    
    contentItem: ColumnLayout {
        spacing: 12
        width: 360
        
        Text {
            text: "The user <b>" + dialog.requesterJid + "</b> wants to see your online status."
            color: window.colText
            font.pixelSize: 14
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            textFormat: Text.RichText
        }
        
        Text {
            text: "Approving will share your presence status. You will also request to subscribe to their status to establish mutual chat communication."
            color: window.colMuted
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
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
                id: denyBtn
                Layout.fillWidth: true
                implicitHeight: 38
                
                contentItem: Text {
                    text: "Ignore"
                    color: window.colDnd
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                
                background: Rectangle {
                    color: denyBtn.down ? "#ef444425" : (denyBtn.hovered ? "#ef444415" : "transparent")
                    border.color: window.colDnd
                    border.width: 1
                    radius: 8
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                
                onClicked: {
                    xmppBackend.denySubscription(dialog.requesterJid)
                    dialog.close()
                }
            }
            
            Button {
                id: approveBtn
                Layout.fillWidth: true
                implicitHeight: 38
                
                contentItem: Text {
                    text: "Accept"
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                
                background: Rectangle {
                    color: approveBtn.down ? window.colPrimaryDark : (approveBtn.hovered ? window.colAccent : window.colPrimary)
                    radius: 8
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                
                onClicked: {
                    xmppBackend.approveSubscription(dialog.requesterJid)
                    dialog.close()
                }
            }
        }
    }
}
