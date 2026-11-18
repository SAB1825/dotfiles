pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services

Rectangle {
    id: root

    required property string fontFamily
    readonly property color foreground: "#ffffff"
    readonly property color secondary: "#adadad"
    readonly property int inset: 14
    readonly property bool empty: Notifications.entries.length === 0

    implicitHeight: 208
    radius: 22
    color: "#121212"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.inset
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Button {
                id: clear
                text: "Clear All"
                enabled: !root.empty
                visible: enabled
                hoverEnabled: true
                horizontalPadding: 9
                verticalPadding: 4
                onClicked: Notifications.clearAll()

                background: Rectangle {
                    color: clear.down ? "#404040" : clear.hovered ? "#303030" : "#222222"
                    radius: height / 2
                    border.color: clear.visualFocus ? root.foreground : "transparent"
                }

                contentItem: Text {
                    text: clear.text
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                visible: root.empty
                spacing: 6

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 36
                    height: 36
                    radius: width / 2
                    color: "#262626"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf0a2"
                        color: root.foreground
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Notifications.available ? "All caught up" : "Notifications unavailable"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }

            ListView {
                id: stack
                anchors.fill: parent
                visible: !root.empty
                clip: true
                model: Notifications.entries
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 4
                    padding: 0
                    contentItem: Rectangle {
                        radius: width / 2
                        color: "#666666"
                    }
                }

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property var notification: modelData.notification

                    width: stack.width - 5
                    height: details.implicitHeight + 16
                    radius: 12
                    color: "#202020"

                    ColumnLayout {
                        id: details
                        anchors {
                            left: parent.left
                            right: dismiss.left
                            top: parent.top
                            leftMargin: 10
                            rightMargin: 6
                            topMargin: 8
                        }
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: card.notification?.appName || "Notification"
                                textFormat: Text.PlainText
                                color: root.secondary
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                text: Qt.formatTime(new Date(card.modelData.receivedAt), "hh:mm")
                                color: root.secondary
                                font.family: root.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.notification?.summary ?? ""
                            textFormat: Text.PlainText
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.notification?.body ?? ""
                            textFormat: Text.PlainText
                            color: root.secondary
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    Button {
                        id: dismiss
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 5
                        width: 25
                        height: 25
                        padding: 0
                        text: "×"
                        hoverEnabled: true
                        Accessible.name: "Dismiss notification"
                        onClicked: Notifications.dismiss(card.modelData)

                        background: Rectangle {
                            radius: width / 2
                            color: dismiss.hovered || dismiss.visualFocus ? "#383838" : "transparent"
                        }

                        contentItem: Text {
                            text: dismiss.text
                            color: root.foreground
                            font.family: root.fontFamily
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
