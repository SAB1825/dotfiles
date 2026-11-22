pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Button {
    id: root

    required property string fontFamily
    required property string title
    required property string detail
    required property string rowAction
    property string iconName: ""

    text: title
    Accessible.description: detail + ", " + rowAction
    hoverEnabled: true
    horizontalPadding: 12
    verticalPadding: 8
    implicitHeight: 54

    background: Rectangle {
        color: Monochrome.background
        radius: 14
        border.color: root.down || root.hovered || root.visualFocus ? Monochrome.accent : Monochrome.outline
    }

    contentItem: RowLayout {
        spacing: 8

        StatusIcon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            iconName: root.iconName
            color: Monochrome.muted
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Monochrome.foreground
                font.family: root.fontFamily
                font.weight: Typography.weight
                font.pixelSize: 14
            }

            Text {
                Layout.fillWidth: true
                text: root.detail
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Monochrome.muted
                font.family: root.fontFamily
                font.weight: Typography.weight
                font.pixelSize: 12
            }
        }

        Text {
            text: root.rowAction
            textFormat: Text.PlainText
            color: root.enabled ? Monochrome.foreground : Monochrome.muted
            font.family: root.fontFamily
            font.weight: Typography.weight
            font.pixelSize: 12
        }
    }
}
