pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../theme"

Button {
    id: root

    required property string fontFamily

    hoverEnabled: true
    horizontalPadding: 12
    verticalPadding: 7

    background: Rectangle {
        radius: height / 2
        color: Monochrome.background
        border.color: root.down || root.hovered || root.visualFocus ? Monochrome.accent : Monochrome.outline
    }

    contentItem: Text {
        text: root.text
        color: root.enabled ? Monochrome.foreground : Monochrome.muted
        font.family: root.fontFamily
        font.weight: Typography.weight
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
