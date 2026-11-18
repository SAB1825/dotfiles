pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

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
            color: "#252525"

            Text {
                anchors.centerIn: parent
                text: "\uf0a2"
                color: "#ffffff"
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
                color: "#adadad"
                font.family: root.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification?.summary ?? ""
                textFormat: Text.PlainText
                color: "#ffffff"
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification?.body ?? ""
                textFormat: Text.PlainText
                color: "#adadad"
                font.family: root.fontFamily
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
