pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string mode: ""

    property var dashboardScreen: null
    readonly property bool dashboardPage: ["dashboard", "wifi", "bluetooth"].includes(mode)

    function toggleDashboard(screen) {
        if (mode === "dashboard" && dashboardScreen === screen) {
            close();
            return;
        }
        dashboardScreen = screen;
        mode = "dashboard";
    }

    function toggle(nextMode) {
        mode = mode === nextMode ? "" : nextMode;
    }

    function close() {
        mode = "";
    }
}
