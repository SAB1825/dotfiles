pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import qs.services

Item {
    id: root

    required property string outputName
    required property font textFont
    property bool expanded: false
    signal clockClicked()

    readonly property color foreground: "#c8cde0"
    readonly property color secondary: "#898e9b"
    readonly property var workspaces: NiriWorkspaces.workspaces
        .filter(workspace => workspace.output === outputName)
        .sort((a, b) => a.idx - b.idx)
    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(player => player.playbackState === MprisPlaybackState.Playing && player.trackTitle)
            ?? players.find(player => player.playbackState === MprisPlaybackState.Paused && player.trackTitle)
            ?? null;
    }
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing

    implicitWidth: 610
    implicitHeight: 140
    opacity: expanded ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 190
            easing.type: Easing.OutCubic
        }
    }

    transform: Translate {
        y: root.expanded ? 0 : -6

        Behavior on y {
            NumberAnimation {
                duration: 270
                easing.type: Easing.OutCubic
            }
        }
    }

    Column {
        id: clock

        anchors {
            left: parent.left
            leftMargin: Math.min(32, parent.width * 0.065)
            verticalCenter: parent.verticalCenter
        }
        width: parent.width * 0.46
        spacing: 2

        Text {
            width: parent.width
            text: Time.hours + ":" + Time.minutes
            elide: Text.ElideRight
            color: root.foreground
            font.family: root.textFont.family
            font.weight: Font.Bold
            font.pixelSize: 36
        }

        Text {
            width: parent.width
            text: Time.calendarDate
            elide: Text.ElideRight
            color: root.secondary
            font.family: root.textFont.family
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: clock
        enabled: root.expanded
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clockClicked()
    }

    Item {
        id: activity
        anchors {
            right: parent.right
            rightMargin: Math.min(32, parent.width * 0.065)
            verticalCenter: parent.verticalCenter
        }
        width: parent.width * 0.39
        height: 58

        Row {
            id: media
            anchors {
                top: parent.top
                right: parent.right
            }
            width: parent.width
            height: 34
            spacing: 9
            visible: opacity > 0
            opacity: root.player ? (root.playing ? 1 : 0.68) : 0

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, media.width - artwork.width - media.spacing)

                Text {
                    width: parent.width
                    text: root.player ? (root.playing ? "" : "Ⅱ  ") + root.player.trackTitle : ""
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    textFormat: Text.PlainText
                    color: root.foreground
                    font.family: root.textFont.family
                    font.weight: Font.Bold
                    font.pixelSize: 13
                }

                Text {
                    width: parent.width
                    text: root.player?.trackArtist ?? ""
                    visible: text !== ""
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    textFormat: Text.PlainText
                    color: root.secondary
                    font.family: root.textFont.family
                    font.pixelSize: 12
                }
            }

            Rectangle {
                id: artwork
                width: 34
                height: 34
                radius: 7
                color: "#191b1f"

                Text {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: "♪"
                    color: root.secondary
                    font.pixelSize: 18
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize.width: 80
                    sourceSize.height: 80
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: media.bottom
                topMargin: 7
            }
            height: 1
            color: "#222326"
            opacity: root.player && root.workspaces.length ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }
        }

        WorkspaceIndicators {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: root.player ? 23 : 0
            }
            workspaces: root.workspaces

            Behavior on anchors.verticalCenterOffset {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
