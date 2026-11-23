import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "app_launcher"
import "clipboard"
import "connectivity"
import "dashboard"
import "island"
import "notifications"
import "theme"
import "wallpaper"

// import qs.theme
// import qs.components
import qs.services

PanelWindow {
    id: island

    signal lockRequested()

    readonly property font islandFont: Qt.font({
        family: Typography.family,
        weight: Typography.weight,
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
    property bool sessionOpen: false
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
    readonly property real compactWidth: 40 + 2 * Math.max(clockHours.implicitWidth, clockMinutes.implicitWidth)
        + (visualizerShown ? 8 * Cava.bars - 4 : 4)

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
        y: island.pickerOpen || island.sessionOpen ? 0 : island.notificationOpen || island.glanceOpen ? 8 : 3
        width: Math.ceil(island.pickerOpen || island.sessionOpen ? island.width
            : Math.min(island.width, island.notificationOpen ? notificationPopup.implicitWidth
                : island.glanceOpen ? glance.implicitWidth
                : Math.max(island.compactWidth, islandReact.width) + 10))
        height: Math.ceil(island.pickerOpen || island.sessionOpen ? island.height
            : island.notificationOpen ? notificationPopup.implicitHeight
            : island.glanceOpen ? glance.implicitHeight : 46)

        Region {
            intersection: Intersection.Combine
            x: workspaceMenu.x
            y: workspaceMenu.y
            width: workspaceMenu.visible ? workspaceMenu.width : 0
            height: workspaceMenu.height
        }

        Region {
            intersection: Intersection.Combine
            x: appMenu.x
            y: appMenu.y
            width: appMenu.visible ? appMenu.width : 0
            height: appMenu.height
        }

        Region {
            intersection: Intersection.Combine
            x: rightMenu.x
            y: rightMenu.y
            width: rightMenu.visible ? rightMenu.width : 0
            height: rightMenu.height
        }

    }
    // Keep the layer surface stable while the island animates and takes focus.
    // The input mask keeps the transparent area click-through when closed.
    implicitWidth: screen?.width ?? 508
    implicitHeight: screen?.height ?? 400
    exclusiveZone: Notifications.focusEnabled ? 0 : 44

    Rectangle {
        id: workspaceMenu

        anchors.left: parent.left
        anchors.leftMargin: 16
        y: 8
        width: workspaceNumbers.width + 12
        height: 36
        radius: 14
        color: Monochrome.background
        visible: !island.pickerVisible && !Notifications.focusEnabled
            && x + width + 12 <= islandReact.x

        Row {
            id: workspaceNumbers
            anchors.centerIn: parent
            spacing: 3

            Repeater {
                model: 5

                IslandMenuButton {
                    id: workspaceButton

                    required property int index
                    readonly property int number: index + 1
                    readonly property var workspace: glance.workspaces.find(entry => entry.number === number)
                    readonly property bool activeWorkspace: workspace?.active ?? false

                    width: 26
                    height: 28
                    topPadding: 3
                    bottomPadding: 3
                    text: number.toString()
                    font.family: island.islandFont.family
                    Accessible.name: "Workspace " + number
                    enabled: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || !!workspace

                    background: Rectangle {
                        radius: 7
                        color: workspaceButton.activeWorkspace ? Monochrome.accent : "transparent"
                    }

                    contentItem: Item {
                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            text: workspaceButton.text
                            font: workspaceButton.font
                            color: workspaceButton.activeWorkspace ? Monochrome.background
                                : workspaceButton.workspace?.occupied ? Monochrome.foreground : Monochrome.muted
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: 10
                            height: 2
                            radius: 1
                            color: workspaceButton.activeWorkspace ? Monochrome.background : Monochrome.accent
                            visible: workspaceButton.workspace?.occupied ?? false
                        }
                    }

                    onClicked: {
                        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
                            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + number + " })"]);
                        else
                            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", number.toString()]);
                    }
                }
            }
        }
    }

    Rectangle {
        id: appMenu

        anchors.left: workspaceMenu.right
        anchors.leftMargin: 8
        y: 8
        width: shortcuts.width + 8
        height: shortcuts.height
        radius: 14
        color: Monochrome.background
        visible: workspaceMenu.visible
            && x + width + 12 <= islandReact.x

        Row {
            id: shortcuts
            anchors.centerIn: parent

            Repeater {
                model: [
                    { label: "Brave", icon: "brave-desktop", ids: ["brave-browser", "com.brave.Browser"], command: ["brave"] },
                    { label: "Kitty", icon: "kitty", ids: ["kitty"], command: ["kitty"] },
                    { label: "Files", icon: "file-manager", ids: ["org.gnome.Nautilus"], command: ["nautilus"] },
                    { label: "Code", icon: "visualstudiocode", ids: [], command: ["/usr/bin/code"] },
                    { label: "Vesktop", icon: "vesktop", ids: ["vesktop", "dev.vencord.Vesktop"], command: ["vesktop"] }
                ]

                IslandMenuButton {
                    id: appButton

                    required property var modelData
                    width: 28
                    height: 36
                    Accessible.name: modelData.label

                    background: Rectangle {
                        x: 1
                        y: 5
                        width: appButton.width - 2
                        height: appButton.height - 10
                        radius: 8
                        color: appButton.pointerHovered || appButton.activeFocus
                            ? Qt.alpha(Monochrome.accent, 0.14) : "transparent"
                    }

                    contentItem: Item {}

                    Image {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: "island/icons/" + appButton.modelData.icon + ".svg"
                        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            autoPaddingEnabled: false
                            colorization: 1
                            colorizationColor: Monochrome.accent
                        }
                    }

                    onClicked: {
                        const entry = modelData.ids.map(id => DesktopEntries.byId(id)).find(entry => entry);
                        if (entry)
                            entry.execute();
                        else
                            Quickshell.execDetached(modelData.command);
                    }
                }
            }
        }
    }

    Row {
        id: rightMenu

        z: island.sessionOpen ? 2 : 0
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: 8
        spacing: 8
        visible: !island.pickerVisible && !Notifications.focusEnabled
            && x >= islandReact.x + islandReact.width + 12
        onVisibleChanged: {
            if (!visible)
                island.sessionOpen = false;
        }

        SystemMonitor {
            id: systemMonitor
            visible: island.width - rightMenu.anchors.rightMargin - systemModule.width - rightMenu.spacing - width
                >= islandReact.x + islandReact.width + 12
        }

        Rectangle {
            id: systemModule
            width: systemControls.width
            height: 36
            radius: 14
            color: Monochrome.background

            Row {
                id: systemControls
                anchors.centerIn: parent

                Item {
                    id: batteryMenu
                    readonly property int percentage: Math.round((DashboardControls.battery?.percentage ?? 0) * 100)
                    readonly property int iconLevel: Math.max(0, Math.min(100, 10 * Math.round(percentage / 10)))

                    visible: !!DashboardControls.battery?.isLaptopBattery
                    width: batteryStatus.width + 20
                    height: 36

                    Row {
                        id: batteryStatus
                        anchors.centerIn: parent
                        spacing: 6

                        StatusIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            iconName: "battery-level-" + batteryMenu.iconLevel
                                + (DashboardControls.onBattery ? "" : "-plugged-in") + "-symbolic"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: batteryMenu.percentage + "%"
                            font.family: island.islandFont.family
                            font.weight: island.islandFont.weight
                            font.pixelSize: 13
                            color: Monochrome.foreground
                        }
                    }
                }

                Item {
                    width: 40
                    height: 36

                    IslandMenuButton {
                        anchors.fill: parent
                        Accessible.name: "Session menu"
                        checkable: true
                        checked: island.sessionOpen
                        onClicked: island.sessionOpen = !island.sessionOpen

                        contentItem: Item {
                            StatusIcon {
                                anchors.centerIn: parent
                                iconName: "system-shutdown-symbolic"
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: island.sessionOpen
        z: 1
        onClicked: island.sessionOpen = false
    }

    SessionMenu {
        anchors.right: rightMenu.right
        anchors.top: rightMenu.bottom
        anchors.topMargin: 8
        fontFamily: island.islandFont.family
        sessionId: Quickshell.env("XDG_SESSION_ID") ?? ""
        visible: island.sessionOpen && rightMenu.visible
        z: 2
        onActionRequested: command => {
            island.sessionOpen = false;
            if (command.length)
                Quickshell.execDetached(command);
            else
                island.lockRequested();
        }
    }

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
            : island.glanceOpen ? glance.implicitWidth : island.compactWidth)
        height: {
            if (island.pickerOpen)
                return Math.min(picker.implicitHeight,
                    Math.max(0, (island.screen?.height ?? picker.implicitHeight + 8) - 8));
            if (island.notificationOpen)
                return notificationPopup.implicitHeight;
            return island.glanceOpen ? glance.implicitHeight : 36;
        }
        radius: island.pickerOpen ? picker.cornerRadius : island.notificationOpen || island.glanceOpen ? 30 : 14
        color: Monochrome.background
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
                        duration: 280
                        easing.type: Easing.OutCubic
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
                        color: Monochrome.accent
                        opacity: firstBar || lastBar ? 1 : visualizer.expansion
                    }
                }
            }

            Text {
                id: clockHours
                anchors.right: visualizer.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: Time.hours
                color: Monochrome.foreground
                font: island.islandFont
            }
            Text {
                id: clockMinutes
                anchors.left: visualizer.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                text: Time.minutes
                color: Monochrome.foreground
                font: island.islandFont
            }
        }
    }
}
