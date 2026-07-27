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
        radius: 2
        
        // Glow effect
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: window.colPrimary
            border.width: 1
            radius: 2
            opacity: 0.2
        }
    }
    
    // Consolidate header, content, and footer into contentItem ColumnLayout to prevent any layout overlapping
    contentItem: ColumnLayout {
        spacing: 16
        width: 360
        
        // Header
        Text {
            text: "Incoming Contact Request"
            color: window.colText
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
        }
        
        // Requester details
        Text {
            text: "The user <b>" + dialog.requesterJid + "</b> wants to see your online status."
            color: window.colText
            font.pixelSize: 14
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            textFormat: Text.RichText
        }
        
        // Detailed information
        Text {
            text: "Approving will share your presence status. You will also request to subscribe to their status to establish mutual chat communication."
            color: window.colMuted
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        
        Item {
            implicitHeight: 8
        }
        
        // Buttons
        RowLayout {
            Layout.fillWidth: true
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
                    radius: 2
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
                    radius: 2
                }
                
                onClicked: {
                    xmppBackend.approveSubscription(dialog.requesterJid)
                    dialog.close()
                }
            }
        }
    }
}
