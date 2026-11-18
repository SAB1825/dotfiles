pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/services/dashboard-controls.sh"
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var battery: UPower.displayDevice
    readonly property bool onBattery: UPower.onBattery
    readonly property bool busy: action.running
    readonly property bool nightLight: nightFilter.running
    property bool nightLightAvailable: false
    property int brightness: -1
    property int pendingBrightness: -1
    property string actionError: ""

    function refresh() {
        if (!snapshot.running && !action.running)
            snapshot.running = true;
    }

    function toggleNightLight() {
        if (!nightLightAvailable)
            return;
        if (actionError === "Night Light couldn't start")
            actionError = "";
        nightFilter.running = !nightFilter.running;
    }

    function setBrightness(value) {
        pendingBrightness = Math.round(value);
        brightnessDelay.restart();
    }

    function runAction(argumentsList) {
        if (!action.running) {
            actionError = "";
            action.requestedBrightness = argumentsList[0] === "brightness" ? Number(argumentsList[1]) : -1;
            action.exec(["bash", script].concat(argumentsList));
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink].filter(node => node !== null)
    }

    Timer {
        id: brightnessDelay
        interval: 70
        onTriggered: {
            if (action.running)
                return;
            const value = root.pendingBrightness;
            if (value >= 0)
                root.runAction(["brightness", String(value)]);
        }
    }

    Process {
        id: snapshot
        command: ["bash", root.script, "status"]
        stdout: StdioCollector { id: status }

        onExited: (code, exitStatus) => {
            if (code !== 0 || exitStatus !== 0 || action.running)
                return;
            const lines = status.text.split("\n");
            root.brightness = lines[0] ? Number(lines[0]) : -1;
            root.nightLightAvailable = lines[1] === "available";
        }
    }

    Process {
        id: action
        property int requestedBrightness: -1

        onExited: (code, exitStatus) => {
            const succeeded = code === 0 && exitStatus === 0;
            if (!succeeded)
                root.actionError = "Couldn't change the setting";
            if (requestedBrightness >= 0) {
                if (succeeded)
                    root.brightness = requestedBrightness;
                if (root.pendingBrightness === requestedBrightness)
                    root.pendingBrightness = -1;
                requestedBrightness = -1;
            }
            if (root.pendingBrightness >= 0)
                brightnessDelay.restart();
            Qt.callLater(root.refresh);
        }
    }

    Process {
        id: nightFilter
        // Keep both ends of the day/night cycle at the same visible warmth.
        command: ["bash", "-c", "exec wlsunset -t 4500 -T 4501 -S 07:00 -s 19:00"]

        onExited: (code, exitStatus) => {
            if (code !== 0 && exitStatus === 0)
                root.actionError = "Night Light couldn't start";
        }
    }
}
