//@ pragma ShellId a8378dd81be67723f52193f42f80438c
//@ pragma Env QSG_RENDER_LOOP=basic
//@ pragma Env QS_ICON_THEME=Tela-circle-dark

import QtQuick
import Quickshell
import Quickshell.Io
import "modules"
import "modules/clipboard"
import "modules/lockscreen"
import qs.services

ShellRoot {
    Component.onCompleted: {
        ClipboardHistory.start();
        Wallpaper.start();
        Notifications.start();
    }

    Binding {
        target: Notifications
        property: "popupsPaused"
        value: IslandState.mode !== ""
    }

    Binding {
        target: Wifi
        property: "scanning"
        value: IslandState.mode === "wifi"
    }

    Binding {
        target: BluetoothControl
        property: "scanning"
        value: IslandState.mode === "bluetooth"
    }

    Connections {
        target: Notifications

        function onFocusEnabledChanged() {
            if (Notifications.focusEnabled)
                IslandState.close();
        }
    }

    LockScreen {
        id: lockScreen
    }

    IpcHandler {
        target: "lockscreen"

        function lock() {
            lockScreen.engage();
        }
    }

    IpcHandler {
        target: "focus"

        function toggle() {
            Notifications.toggleFocus();
        }
    }

    IpcHandler {
        target: "applauncher"

        function toggle() {
            IslandState.toggle("apps");
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle() {
            IslandState.toggle("clipboard");
        }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle() {
            IslandState.toggle("wallpaper");
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: perScreen

            required property var modelData

            Island {
                screen: perScreen.modelData
                onLockRequested: lockScreen.engage()
            }
        }
    }
}
