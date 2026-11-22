import QtQuick
import QtQuick.Controls

Button {
    id: button

    height: 28
    leftPadding: 10
    rightPadding: 10
    font.pixelSize: 13
    font.weight: Font.Medium

    contentItem: Text {
        text: button.text
        font: button.font
        color: "#f5f5f5"
        verticalAlignment: Text.AlignVCenter
    }

    background: null

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
