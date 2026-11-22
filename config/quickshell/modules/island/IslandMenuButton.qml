import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: button

    readonly property bool pointerHovered: hoverArea.containsMouse

    height: 28
    leftPadding: 10
    rightPadding: 10
    font.pixelSize: 13
    font.family: Typography.family
    font.weight: Typography.weight

    contentItem: Text {
        text: button.text
        font: button.font
        color: Monochrome.foreground
        verticalAlignment: Text.AlignVCenter
    }

    background: null

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
