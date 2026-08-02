import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property string source: ""
    property color color: "white"
    property size sourceSize: Qt.size(width, height)

    implicitWidth: 20
    implicitHeight: 20

    Image {
        id: srcImg
        anchors.fill: parent
        source: root.source
        sourceSize: root.sourceSize
        visible: false
        asynchronous: true
    }

    ColorOverlay {
        anchors.fill: srcImg
        source: srcImg
        color: root.color
        cached: true
    }
}
