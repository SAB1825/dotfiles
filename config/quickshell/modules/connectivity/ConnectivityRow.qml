pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root

    required property string fontFamily
    required property string title
    required property string detail
    required property string rowAction
    property string glyph: ""

    text: title
    Accessible.description: detail + ", " + rowAction
    hoverEnabled: true
    horizontalPadding: 12
    verticalPadding: 8
    implicitHeight: 54

    background: Rectangle {
        color: root.down ? "#303030" : root.hovered ? "#262626" : "#151515"
        radius: 14
        border.color: root.visualFocus ? "#ffffff" : "transparent"
    }

    contentItem: RowLayout {
        spacing: 8

        Text {
            visible: text !== ""
            text: root.glyph
            color: "#b0b0b0"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.title
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: "#ffffff"
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.detail
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: "#b0b0b0"
                font.family: root.fontFamily
                font.pixelSize: 12
            }
        }

        Text {
            text: root.rowAction
            textFormat: Text.PlainText
            color: root.enabled ? "#ffffff" : "#b0b0b0"
            font.family: root.fontFamily
            font.pixelSize: 12
        }
    }
}
