pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    required property string fontFamily
    property var notification: null
    signal openDashboard()

    implicitWidth: 408
    implicitHeight: 104

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: width / 2
            color: Monochrome.background

            Text {
                anchors.centerIn: parent
                text: "\uf0a2"
                color: Monochrome.foreground
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.notification?.appName || "Notification"
                textFormat: Text.PlainText
                color: Monochrome.muted
                font.family: root.fontFamily
                font.weight: Typography.weight
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification?.summary ?? ""
                textFormat: Text.PlainText
                color: Monochrome.foreground
                font.family: root.fontFamily
                font.weight: Typography.weight
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification?.body ?? ""
                textFormat: Text.PlainText
                color: Monochrome.muted
                font.family: root.fontFamily
                font.weight: Typography.weight
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openDashboard()
    }
}
