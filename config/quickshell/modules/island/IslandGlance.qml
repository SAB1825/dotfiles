pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.services
import "../theme"

Item {
    id: root

    required property string outputName
    required property font textFont
    property bool expanded: false
    signal clockClicked()

    readonly property color foreground: Monochrome.foreground
    readonly property color secondary: Monochrome.muted
    readonly property var workspaces: {
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) {
            return Hyprland.workspaces.values
                .filter(workspace => workspace.monitor?.name === root.outputName
                    && !workspace.name.startsWith("special:") && workspace.name !== "special")
                .sort((a, b) => a.id - b.id)
                .map(workspace => ({
                    number: workspace.id,
                    active: workspace.active,
                    occupied: workspace.toplevels.values.length > 0
                }));
        }

        return NiriWorkspaces.workspaces
            .filter(workspace => workspace.output === root.outputName)
            .sort((a, b) => a.idx - b.idx)
            .map(workspace => ({
                number: workspace.idx,
                active: workspace.is_active,
                occupied: workspace.active_window_id != null
            }));
    }
    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(player => player.isPlaying)
            ?? players.find(player => player.playbackState === MprisPlaybackState.Paused && player.trackTitle)
            ?? null;
    }
    readonly property bool hasPosition: player?.positionSupported ?? false
    readonly property real duration: player?.lengthSupported ? player.length : 0
    readonly property real elapsed: hasPosition ? Math.max(0, player.position) : 0

    function formatTrackTime(seconds) {
        const wholeSeconds = Math.floor(seconds);
        return Math.floor(wholeSeconds / 60) + ":" + String(wholeSeconds % 60).padStart(2, "0");
    }

    Timer {
        running: root.expanded && root.hasPosition && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    implicitWidth: player ? 610 : 390
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
            font.weight: root.textFont.weight
            font.pixelSize: 36
        }

        Text {
            width: parent.width
            text: Time.calendarDate
            elide: Text.ElideRight
            color: root.secondary
            font.family: root.textFont.family
            font.weight: root.textFont.weight
            font.pixelSize: 14
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
        width: parent.width * 0.43
        height: 84

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
            opacity: root.player ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, media.width - artwork.width - media.spacing)

                Text {
                    width: parent.width
                    text: root.player?.trackTitle || "Unknown track"
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    textFormat: Text.PlainText
                    color: root.foreground
                    font.family: root.textFont.family
                    font.weight: root.textFont.weight
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
                    font.weight: root.textFont.weight
                    font.pixelSize: 12
                }
            }

            Rectangle {
                id: artwork
                width: 34
                height: 34
                radius: 7
                color: Monochrome.background

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

        Item {
            id: playback

            anchors {
                left: parent.left
                right: parent.right
                top: media.bottom
                topMargin: 8
            }
            height: 28
            visible: !!root.player

            Row {
                id: transport
                anchors.left: parent.left
                spacing: 3

                Repeater {
                    model: [
                        { glyph: "\uf048", label: "Previous track", enabled: root.player?.canGoPrevious ?? false },
                        { glyph: root.player?.isPlaying ? "\uf04c" : "\uf04b",
                            label: root.player?.isPlaying ? "Pause" : "Play",
                            enabled: root.player?.canTogglePlaying ?? false },
                        { glyph: "\uf051", label: "Next track", enabled: root.player?.canGoNext ?? false }
                    ]

                    IslandMenuButton {
                        id: playbackButton

                        required property int index
                        required property var modelData

                        width: 28
                        leftPadding: 0
                        rightPadding: 0
                        text: modelData.glyph
                        font.family: root.textFont.family
                        font.weight: root.textFont.weight
                        Accessible.name: modelData.label
                        enabled: root.expanded && modelData.enabled
                        opacity: enabled ? 1 : 0.35

                        contentItem: Text {
                            text: modelData.glyph
                            font: playbackButton.font
                            color: root.foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            switch (index) {
                            case 0: root.player?.previous(); break;
                            case 1: root.player?.togglePlaying(); break;
                            case 2: root.player?.next(); break;
                            }
                        }
                    }
                }
            }

            Text {
                anchors.left: transport.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                visible: root.hasPosition
                text: root.formatTrackTime(root.elapsed)
                    + (root.duration > 0 ? " / " + root.formatTrackTime(root.duration) : "")
                font.family: root.textFont.family
                font.weight: root.textFont.weight
                font.pixelSize: 12
                color: root.secondary
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: playback.bottom
                topMargin: 6
            }
            height: 2
            radius: 1
            color: Monochrome.outline
            visible: root.hasPosition && root.duration > 0

            Rectangle {
                width: root.duration > 0 ? parent.width * Math.min(1, root.elapsed / root.duration) : 0
                height: parent.height
                radius: parent.radius
                color: root.foreground
            }
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.player
            text: "No media playing"
            font.family: root.textFont.family
            font.weight: root.textFont.weight
            font.pixelSize: 12
            color: root.secondary
        }
    }
}
