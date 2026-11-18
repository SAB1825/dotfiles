pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

Button {
    id: root

    required property string fontFamily

    hoverEnabled: true
    horizontalPadding: 12
    verticalPadding: 7

    background: Rectangle {
        radius: height / 2
        color: root.down ? "#404040" : root.hovered ? "#303030" : "#222222"
        border.color: root.visualFocus ? "#ffffff" : "transparent"
    }

    contentItem: Text {
        text: root.text
        color: root.enabled ? "#ffffff" : "#777777"
        font.family: root.fontFamily
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
