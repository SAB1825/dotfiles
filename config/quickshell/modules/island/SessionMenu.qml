pragma ComponentBehavior: Bound

import QtQuick

Rectangle {
    id: menu

    required property string fontFamily
    required property string sessionId
    signal actionRequested(var command)

    width: 152
    height: actions.implicitHeight + 16
    radius: 14
    color: "#000000"
    border.color: "#343943"

    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: actions

        anchors.fill: parent
        anchors.margins: 8

        Repeater {
            model: [
                { label: "Lock", command: [] },
                { label: "Suspend", command: ["systemctl", "suspend"] },
                { label: "Log out", command: ["loginctl", "terminate-session", menu.sessionId] },
                { label: "Restart", command: ["systemctl", "reboot"] },
                { label: "Shut down", command: ["systemctl", "poweroff"] }
            ]

            IslandMenuButton {
                required property var modelData
                width: actions.width
                text: modelData.label
                font.family: menu.fontFamily
                visible: modelData.label !== "Log out" || menu.sessionId !== ""
                onClicked: menu.actionRequested(modelData.command)
            }
        }
    }
}
