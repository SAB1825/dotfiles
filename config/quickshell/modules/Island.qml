import QtQuick
import Quickshell
import Quickshell.Wayland
import "app_launcher"
import "clipboard"
import "connectivity"
import "dashboard"
import "island"
import "notifications"
import "wallpaper"

// import qs.theme
// import qs.components
import qs.services

PanelWindow {
    id: island

    readonly property font islandFont: Qt.font({
        family: "SF Pro",
        weight: Font.Bold,
        pixelSize: 16
    })

    readonly property var pickerScreen: IslandState.dashboardPage
        ? IslandState.dashboardScreen : Quickshell.screens[0]
    readonly property string activeMode: screen === pickerScreen ? IslandState.mode : ""
    readonly property bool pickerOpen: activeMode !== ""
    readonly property bool pickerVisible: pickerOpen || displayedMode !== ""
    readonly property bool notificationOpen: screen === Quickshell.screens[0]
        && !pickerVisible && !Notifications.popupsPaused && Notifications.popup !== null
    property bool hoverExpanded: false
    readonly property bool glanceOpen: hoverExpanded && !pickerVisible && !notificationOpen
    property string displayedMode: ""
    readonly property Item picker: {
        switch (displayedMode) {
        case "clipboard": return clipboard;
        case "dashboard": return dashboard;
        case "wifi": return wifi;
        case "bluetooth": return bluetooth;
        case "wallpaper": return wallpaper;
        default: return launcher;
        }
    }

    onActiveModeChanged: {
        if (activeMode) {
            displayedMode = activeMode;
            hoverExpanded = false;
        }
    }

    onPickerOpenChanged: {
        if (!pickerOpen) {
            Qt.callLater(() => {
                if (!island.pickerOpen && !resizeHeight.running)
                    island.displayedMode = "";
            });
        }
    }
    Timer {
        interval: 220
        running: islandHover.hovered && !island.pickerVisible && !island.notificationOpen && !island.hoverExpanded
        onTriggered: island.hoverExpanded = true
    }

    Timer {
        interval: 160
        running: !islandHover.hovered && island.hoverExpanded
        onTriggered: island.hoverExpanded = false
    }

    readonly property bool isPlaying: Cava.total !== 0
    property bool visualizerShown: false

    onIsPlayingChanged: {
        if (isPlaying)
            visualizerShown = true;
    }

    Timer {
        interval: 1000
        repeat: false
        running: !island.isPlaying
        onTriggered: visualizerShown = false
    }

    anchors {
        top: true
    }
    visible: !Notifications.focusEnabled || pickerVisible
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: pickerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    // Keep pointer input stable while the painted island changes size.
    mask: Region {
        x: Math.floor((island.width - width) / 2)
        y: island.pickerOpen ? 0 : island.notificationOpen || island.glanceOpen ? 8 : 3
        width: Math.ceil(island.pickerOpen ? island.width
            : Math.min(island.width, island.notificationOpen ? notificationPopup.implicitWidth
                : island.glanceOpen ? glance.implicitWidth : 210))
        height: Math.ceil(island.pickerOpen ? island.height
            : island.notificationOpen ? notificationPopup.implicitHeight
            : island.glanceOpen ? glance.implicitHeight : 46)
    }
    // Keep the layer surface stable while the island animates and takes focus.
    // The input mask keeps the transparent area click-through when closed.
    implicitWidth: screen?.width ?? 508
    implicitHeight: screen?.height ?? 400
    exclusiveZone: Notifications.focusEnabled ? 0 : 44

    MouseArea {
        id: dismissArea
        anchors.fill: parent
        enabled: island.pickerOpen
        onClicked: IslandState.close()
    }

    Rectangle {
        id: islandReact
        readonly property real audioOffset: (Cava.levels[Math.floor(Cava.bars / 2)] ?? 0) - (Cava.levels[0] ?? 0)
        y: (island.pickerVisible || island.notificationOpen || island.glanceOpen) ? 8 : 8 + audioOffset * 4

        anchors.horizontalCenter: parent.horizontalCenter
        scale: (island.pickerVisible || island.notificationOpen || island.glanceOpen) ? 1 : 1 + audioOffset * 0.05
        width: Math.min(island.width, island.pickerOpen ? picker.implicitWidth
            : island.notificationOpen ? notificationPopup.implicitWidth
            : island.glanceOpen ? glance.implicitWidth : 200)
        height: {
            if (island.pickerOpen)
                return Math.min(picker.implicitHeight,
                    Math.max(0, (island.screen?.height ?? picker.implicitHeight + 8) - 8));
            if (island.notificationOpen)
                return notificationPopup.implicitHeight;
            return island.glanceOpen ? glance.implicitHeight : 36;
        }
        radius: island.pickerOpen ? picker.cornerRadius : island.notificationOpen || island.glanceOpen ? 30 : 14
        color: "#000000"
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                id: resizeHeight
                onRunningChanged: {
                    if (!running && !island.pickerOpen)
                        island.displayedMode = "";
                }
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: islandHover
            enabled: !island.pickerVisible && !island.notificationOpen
        }

        MouseArea {
            anchors.fill: parent
            enabled: island.pickerOpen
        }

        Applauncher {
            id: launcher
            anchors.fill: parent
            textFont: island.islandFont
            open: island.activeMode === "apps"
            visible: island.pickerVisible && island.displayedMode === "apps"
            onDismissRequested: IslandState.close()
        }

        ClipboardView {
            id: clipboard
            anchors.fill: parent
            textFont: island.islandFont
            open: island.activeMode === "clipboard"
            visible: island.pickerVisible && island.displayedMode === "clipboard"
            onDismissRequested: IslandState.close()
        }

        Dashboard {
            id: dashboard
            anchors.fill: parent
            textFont: island.islandFont
            open: island.activeMode === "dashboard"
            visible: island.pickerVisible && island.displayedMode === "dashboard"
            onDismissRequested: IslandState.close()
            onWifiRequested: IslandState.mode = "wifi"
            onBluetoothRequested: IslandState.mode = "bluetooth"
        }

        WifiPanel {
            id: wifi
            anchors.fill: parent
            textFont: island.islandFont
            open: island.activeMode === "wifi"
            visible: island.pickerVisible && island.displayedMode === "wifi"
            onBackRequested: IslandState.mode = "dashboard"
            onDismissRequested: IslandState.close()
        }

        BluetoothPanel {
            id: bluetooth
            anchors.fill: parent
            textFont: island.islandFont
            open: island.activeMode === "bluetooth"
            visible: island.pickerVisible && island.displayedMode === "bluetooth"
            onBackRequested: IslandState.mode = "dashboard"
        }

        WallpaperPicker {
            id: wallpaper
            anchors.fill: parent
            textFont: island.islandFont
            open: island.activeMode === "wallpaper"
            visible: island.pickerVisible && island.displayedMode === "wallpaper"
            onDismissRequested: IslandState.close()
        }

        NotificationPopup {
            id: notificationPopup
            anchors.fill: parent
            visible: island.notificationOpen
            fontFamily: island.islandFont.family
            notification: visible ? Notifications.popup?.notification ?? null : null

            onOpenDashboard: {
                Notifications.advancePopup();
                IslandState.toggleDashboard(island.screen);
            }
        }

        IslandGlance {
            id: glance
            anchors.fill: parent
            outputName: island.screen?.name ?? ""
            textFont: island.islandFont
            expanded: island.glanceOpen
            onClockClicked: IslandState.toggleDashboard(island.screen)
            visible: !island.pickerVisible && !island.notificationOpen && opacity > 0
        }

        Item {
            anchors.fill: parent
            visible: !island.pickerVisible && !island.notificationOpen && opacity > 0
            opacity: island.glanceOpen ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: 130 }
            }

            Row {
                id: visualizer
                property real expansion: island.visualizerShown ? 1 : 0

                anchors.centerIn: parent
                spacing: -3.99 + 7.99 * expansion

                Behavior on expansion {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutQuint
                    }
                }

                Repeater {
                    model: Cava.bars

                    delegate: Rectangle {
                        required property int index
                        readonly property bool firstBar: index === 0
                        readonly property bool lastBar: index === Cava.bars - 1

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: (firstBar ? -4 : lastBar ? 4 : 0) * (1 - visualizer.expansion)
                        width: 4
                        height: Math.max(4, (Cava.levels[index] ?? 0) * 24)
                        radius: 2
                        color: "#FF0000"
                        opacity: firstBar || lastBar ? 1 : visualizer.expansion
                    }
                }
            }

            Text {
                anchors.right: visualizer.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: Time.hours
                color: "#FFFFFF"
                font: island.islandFont
            }
            Text {
                anchors.left: visualizer.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: Time.minutes
                color: "#FFFFFF"
                font: island.islandFont
            }
        }
    }
}
