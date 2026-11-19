pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../notifications"
import "../theme"
import qs.services

FocusScope {
    id: root

    required property font textFont
    property bool open: false
    signal dismissRequested()
    signal wifiRequested()
    signal bluetoothRequested()

    readonly property int cornerRadius: 30
    readonly property color foreground: Monochrome.foreground
    readonly property color secondary: Monochrome.muted
    readonly property color surface: Monochrome.background
    readonly property color raised: Monochrome.raised
    readonly property int inset: 16
    readonly property int sectionSpacing: 10
    readonly property var battery: DashboardControls.battery
    readonly property real batteryFraction: Math.max(0, Math.min(1, battery?.percentage ?? 0))

    implicitWidth: 432
    implicitHeight: Math.min(620, content.implicitHeight + 2 * inset)
    enabled: open
    opacity: open ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 180 }
    }

    transform: Translate {
        y: root.open ? 0 : -8

        Behavior on y {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
    }

    onOpenChanged: {
        if (!open)
            return;
        scroll.contentItem.contentY = 0;
        Notifications.checkAvailability();
        Qt.callLater(() => {
            if (root.open)
                root.forceActiveFocus();
        });
    }

    Keys.onEscapePressed: root.dismissRequested()

    Timer {
        interval: 1500
        running: root.open
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!displayLevel.dragging && !soundLevel.dragging)
                DashboardControls.refresh();
        }
    }

    component Caption: Text {
        color: root.secondary
        font.family: root.textFont.family
        font.pixelSize: 13
        textFormat: Text.PlainText
    }

    component Tile: Button {
        id: tile
        required property string detail
        required property string iconName
        required property bool active

        Layout.fillWidth: true
        implicitHeight: 60
        leftPadding: 10
        rightPadding: 14
        verticalPadding: 11
        hoverEnabled: true
        Accessible.description: detail

        background: Rectangle {
            radius: height / 2
            color: tile.down || tile.hovered ? root.raised : root.surface
            border.color: tile.visualFocus ? Monochrome.accent : Monochrome.outline
        }

        contentItem: RowLayout {
            spacing: 10
            opacity: tile.enabled ? 1 : 0.62

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: width / 2
                color: tile.active ? Monochrome.accent : root.raised

                StatusIcon {
                    anchors.centerIn: parent
                    width: 18
                    height: width
                    iconName: tile.iconName
                    color: tile.active ? Monochrome.accentText : Monochrome.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Caption {
                    Layout.fillWidth: true
                    text: tile.text
                    color: root.foreground
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Caption {
                    Layout.fillWidth: true
                    text: tile.detail
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
    }

    component Level: Rectangle {
        id: level
        required property string label
        required property string iconName
        required property real percent
        readonly property bool dragging: slider.pressed
        property real dragValue: -1
        signal adjusted(real value)

        function commit(value) {
            const rounded = Math.round(value);
            if (rounded !== Math.round(percent))
                adjusted(rounded);
        }

        Layout.fillWidth: true
        implicitHeight: 62
        radius: 21
        color: root.surface

        RowLayout {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 8
                leftMargin: 14
                rightMargin: 14
            }

            Caption {
                Layout.fillWidth: true
                text: level.label
                color: root.foreground
                font.weight: Font.DemiBold
            }

            Caption {
                text: slider.enabled ? Math.round(slider.position * slider.to) + "%" : "—"
                font.pixelSize: 12
            }
        }

        Slider {
            id: slider
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 10
            }
            height: 24
            padding: 0
            enabled: level.percent >= 0
            from: 0
            to: 100
            stepSize: 1
            live: false
            Accessible.name: level.label

            Binding on value {
                when: !slider.pressed && level.dragValue < 0
                value: Math.max(0, level.percent)
                restoreMode: Binding.RestoreNone
            }

            onPressedChanged: {
                if (pressed) {
                    level.dragValue = position * to;
                } else {
                    if (enabled)
                        level.commit(level.dragValue);
                    level.dragValue = -1;
                }
            }
            onMoved: {
                if (pressed)
                    level.dragValue = position * to;
                else if (level.dragValue < 0)
                    level.commit(value);
            }

            background: Rectangle {
                width: slider.width
                height: slider.height
                radius: height / 2
                color: root.raised
                border.color: slider.visualFocus ? root.foreground : "transparent"

                Rectangle {
                    width: slider.enabled
                        ? Math.min(parent.width, Math.max(40, slider.visualPosition * parent.width))
                        : 0
                    height: parent.height
                    radius: height / 2
                    color: Monochrome.accent
                }
            }

            handle: Item {
                // The icon is a fixed label, so it should not shorten the drag range.
                width: 0
                height: slider.height

                StatusIcon {
                    x: 12
                    width: 16
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: level.iconName
                    color: slider.enabled ? Monochrome.accentText : root.secondary
                }
            }
        }
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: root.inset
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: content
            width: scroll.availableWidth
            spacing: root.sectionSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 7

                Button {
                    id: clockButton
                    Layout.rightMargin: 4
                    implicitHeight: 20
                    padding: 0
                    text: Time.hours + ":" + Time.minutes
                    Accessible.name: Time.calendarDate + ", " + text + ", close dashboard"
                    hoverEnabled: true
                    onClicked: root.dismissRequested()

                    background: Rectangle {
                        radius: 4
                        color: clockButton.hovered || clockButton.visualFocus ? root.raised : "transparent"
                    }

                    contentItem: Caption {
                        verticalAlignment: Text.AlignVCenter
                        text: clockButton.text
                        color: root.foreground
                        font.weight: Font.DemiBold
                    }
                }

                Item { Layout.fillWidth: true }

                Caption {
                    visible: !!root.battery?.isLaptopBattery && !DashboardControls.onBattery
                    text: "Plugged in"
                    font.pixelSize: 11
                }

                Caption {
                    visible: !!root.battery?.isLaptopBattery
                    text: Math.round(root.batteryFraction * 100) + "%"
                    color: root.foreground
                    font.pixelSize: 11
                }

                Item {
                    visible: !!root.battery?.isLaptopBattery
                    Layout.preferredWidth: 23
                    Layout.preferredHeight: 11

                    Rectangle {
                        width: 20
                        height: parent.height
                        radius: 3
                        color: "transparent"
                        border.color: root.secondary

                        Rectangle {
                            x: 2
                            y: 2
                            width: Math.round((parent.width - 4) * root.batteryFraction)
                            height: parent.height - 4
                            radius: 1
                            color: Monochrome.accent
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 5
                        radius: 1
                        color: root.secondary
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: root.sectionSpacing
                rowSpacing: root.sectionSpacing
                uniformCellWidths: true

                Tile {
                    text: "Wi-Fi"
                    iconName: Wifi.enabled ? "network-wireless-symbolic" : "network-wireless-disabled-symbolic"
                    active: Wifi.enabled
                    detail: Wifi.status
                    onClicked: root.wifiRequested()
                }

                Tile {
                    text: "Focus"
                    iconName: active ? "user-busy-symbolic" : "user-available-symbolic"
                    active: Notifications.focusEnabled
                    detail: active ? "On" : "Off"
                    onClicked: Notifications.toggleFocus()
                }

                Tile {
                    text: "Bluetooth"
                    iconName: !BluetoothControl.enabled ? "bluetooth-disabled-symbolic"
                        : BluetoothControl.connected.length ? "bluetooth-paired-symbolic" : "bluetooth-active-symbolic"
                    active: BluetoothControl.enabled
                    detail: BluetoothControl.status
                    onClicked: root.bluetoothRequested()
                }

                Tile {
                    text: "Night Light"
                    iconName: active ? "night-light-symbolic" : "night-light-disabled-symbolic"
                    active: DashboardControls.nightLight
                    enabled: DashboardControls.nightLightAvailable
                    detail: active ? "On · 4500 K" : enabled ? "Off" : "Requires wlsunset"
                    onClicked: DashboardControls.toggleNightLight()
                }
            }

            Level {
                id: displayLevel
                label: "Display"
                iconName: "display-brightness-symbolic"
                percent: DashboardControls.pendingBrightness >= 0 ? DashboardControls.pendingBrightness : DashboardControls.brightness
                onAdjusted: value => DashboardControls.setBrightness(value)
            }

            Level {
                id: soundLevel
                label: "Sound"
                iconName: DashboardControls.audio?.muted || percent <= 0 ? "audio-volume-muted-symbolic"
                    : percent < 0.34 ? "audio-volume-low-symbolic"
                    : percent < 0.67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic"
                percent: DashboardControls.audio ? DashboardControls.audio.volume * 100 : -1
                onAdjusted: value => {
                    const audio = DashboardControls.audio;
                    if (audio)
                        audio.volume = value / 100;
                }
            }

            Caption {
                Layout.fillWidth: true
                visible: text !== ""
                text: DashboardControls.actionError
                wrapMode: Text.Wrap
            }

            NotificationCenter {
                Layout.fillWidth: true
                fontFamily: root.textFont.family
            }
        }
    }
}
