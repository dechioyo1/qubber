import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: interactmessagepaneldelegate
    objectName: "interactmessagepaneldelegate"

    property string editingText: ""
    property int editingMsgId: 0
    property int editingRowIndex: -1

    signal cancelRequested()
    signal jumpRequested()

    visible: editingMsgId !== 0
    implicitHeight: visible ? 48 : 0
    Layout.fillWidth: true

    color: "#0f172a"

    // Top border divider
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: window.colBorder
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        // Blue Pencil Icon
        TintedIcon {
            width: 20
            height: 20
            source: "icons/edit.svg"
            color: (typeof window !== "undefined" && window) ? window.colAccent : "#3b82f6"
            sourceSize: Qt.size(20, 20)
            Layout.alignment: Qt.AlignVCenter
        }

        // Former Message Text & Title Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: interactmessagepaneldelegate.jumpRequested()
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "Edit message"
                    color: (typeof window !== "undefined" && window) ? window.colAccent : "#3b82f6"
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: interactmessagepaneldelegate.editingText
                    color: (typeof window !== "undefined" && window) ? window.colText : "#e2e8f0"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                }
            }
        }

        // Close / Cancel Button
        Button {
            id: cancelBtn
            implicitWidth: 28
            implicitHeight: 28
            Layout.alignment: Qt.AlignVCenter

            contentItem: Text {
                text: "✕"
                color: cancelBtn.hovered ? "white" : ((typeof window !== "undefined" && window) ? window.colMuted : "#94a3b8")
                font.pixelSize: 15
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: cancelBtn.hovered ? "#33415540" : "transparent"
                radius: 14
            }

            onClicked: interactmessagepaneldelegate.cancelRequested()
        }
    }
}
