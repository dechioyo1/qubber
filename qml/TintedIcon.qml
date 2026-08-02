import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property string source: ""
    property color color: "white"
    property size sourceSize: Qt.size(width, height)

    // Ensure high-resolution SVG vector rasterization (minimum 96x96 or 4x size)
    // to guarantee razor-sharp icon rendering on all screens and HiDPI displays.
    readonly property size vectorRenderSize: Qt.size(
        Math.max(96, Math.round((sourceSize.width > 0 ? sourceSize.width : width) * 4)),
        Math.max(96, Math.round((sourceSize.height > 0 ? sourceSize.height : height) * 4))
    )

    implicitWidth: 20
    implicitHeight: 20

    Image {
        id: srcImg
        anchors.fill: parent
        source: root.source
        sourceSize: root.vectorRenderSize
        smooth: true
        mipmap: true
        visible: false
        asynchronous: false
    }

    ColorOverlay {
        anchors.fill: parent
        source: srcImg
        color: root.color
        cached: false
    }
}
