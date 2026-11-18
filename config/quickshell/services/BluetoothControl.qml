pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter ?? null
    readonly property bool available: adapter !== null
    readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool powerChanging: adapter?.state === BluetoothAdapterState.Enabling
        || adapter?.state === BluetoothAdapterState.Disabling
    readonly property var devices: (adapter?.devices.values ?? []).filter(device => !device.blocked)
        .sort((a, b) => Number(b.connected) - Number(a.connected)
            || Number(b.paired) - Number(a.paired)
            || (a.name || a.address).localeCompare(b.name || b.address))
    readonly property var connected: devices.filter(device => device.connected)
    readonly property string status: !available ? (serviceUnavailable ? "Bluetooth service unavailable" : "No Bluetooth adapter")
        : blocked ? "Blocked"
        : !enabled ? "Off" : connected.length === 1 ? (connected[0].name || connected[0].address)
        : connected.length ? connected.length + " connected" : "On"

    property bool scanning: false
    property bool serviceUnavailable: false
    property var pairDevice: null
    property var connectionDevice: null
    property bool connecting: false
    property string error: ""
    property string promptKind: ""
    property string promptText: ""
    property int handledPrompt: -1
    property bool pairCommandSent: false

    onScanningChanged: {
        if (scanning && !available && !serviceCheck.running)
            serviceCheck.running = true;
    }

    function toggle() {
        if (!available || blocked || powerChanging)
            return;
        error = "";
        if (enabled)
            cancelPairing();
        adapter.enabled = !enabled;
    }

    function changeConnection(device) {
        if (!device || !enabled || blocked || connectionDevice || pairDevice)
            return;
        error = "";
        if (!device.paired && !device.connected) {
            startPairing(device);
            return;
        }

        connecting = !device.connected;
        connectionDevice = device;
        connectionTimeout.restart();
        if (connecting)
            device.connect();
        else
            device.disconnect();
    }

    function forget(device) {
        if (!device || !enabled || pairDevice || connectionDevice)
            return;
        error = "";
        device.forget();
    }

    function startPairing(device) {
        if (!/^([0-9a-f]{2}:){5}[0-9a-f]{2}$/i.test(device.address))
            return;
        if (agent.running) {
            error = "Wait for the previous pairing session to close.";
            return;
        }

        pairDevice = device;
        pairCommandSent = false;
        handledPrompt = -1;
        promptKind = "";
        promptText = "";
        agent.running = true;
        pairingTimeout.restart();
    }

    function handlePairingOutput(output) {
        if (!pairDevice)
            return;
        const text = output.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
        if (!pairCommandSent) {
            if (/(?:^|[\r\n])Agent registered(?:[\r\n]|$)/.test(text)) {
                pairCommandSent = true;
                agent.write("pair " + pairDevice.address + "\n");
            }
            return;
        }

        if (/(?:^|[\r\n])Pairing successful(?:[\r\n]|$)/.test(text)) {
            finishPairing("");
            return;
        }
        if (/(?:^|[\r\n])(?:Failed to pair|Device [0-9A-F:]+ not available|Request canceled)/i.test(text)) {
            finishPairing("Pairing failed. Check that the device is in pairing mode.");
            return;
        }

        const pattern = /(?:^|[\r\n])\s*\[agent\]\s*(?:Confirm passkey (\d{6}) \(yes\/no\):|Enter PIN code:|Enter passkey \(number in 0-999999\):|(?:Passkey|PIN code):[ \t]*([0-9A-Za-z]{1,16})(?=[ \t\r\n])|(?:Authorize service [^\r\n]*|Accept pairing) \(yes\/no\):)/g;
        let latest = null;
        let match;
        while ((match = pattern.exec(text)) !== null)
            latest = match;
        if (!latest || latest.index <= handledPrompt)
            return;

        handledPrompt = latest.index;
        if (latest[1]) {
            promptKind = "confirm";
            promptText = "Does " + latest[1] + " match the code on the device?";
        } else if (latest[2]) {
            promptKind = "display";
            promptText = "Enter " + latest[2] + " on the device.";
        } else if (latest[0].includes("yes/no")) {
            promptKind = "confirm";
            promptText = "Allow this Bluetooth pairing request?";
        } else {
            promptKind = latest[0].includes("PIN") ? "pin" : "passkey";
            promptText = promptKind === "pin" ? "Enter the device PIN." : "Enter the device passkey.";
        }
    }

    function answerPairing(response) {
        if (!pairDevice || !agent.running)
            return;
        if (promptKind === "confirm") {
            if (response !== "yes" && response !== "no")
                return;
        } else if (promptKind === "pin") {
            if (!/^[\x20-\x7e]{1,16}$/.test(response))
                return;
        } else if (promptKind === "passkey") {
            if (!/^\d{1,6}$/.test(response))
                return;
        } else {
            return;
        }

        promptKind = "";
        promptText = "";
        agent.write(response + "\n");
        if (response === "no")
            finishPairing("Pairing declined.");
    }

    function cancelPairing() {
        if (pairDevice)
            finishPairing("");
    }

    function finishPairing(message) {
        const device = pairDevice;
        pairDevice = null;
        promptKind = "";
        promptText = "";
        pairingTimeout.stop();
        error = message;
        agent.running = false;
        if (message && device?.pairing)
            device.cancelPair();
    }

    Binding {
        target: root.adapter ?? null
        property: "discovering"
        when: !!root.adapter && root.scanning && root.enabled && !root.blocked
        value: true
    }

    Connections {
        target: root.connectionDevice ?? null

        function onConnectedChanged() {
            if (root.connectionDevice && root.connectionDevice.connected === root.connecting) {
                connectionTimeout.stop();
                root.connectionDevice = null;
            }
        }
    }

    Timer {
        id: connectionTimeout
        interval: 18000
        onTriggered: {
            root.connectionDevice = null;
            root.error = root.connecting ? "Couldn't connect to the device." : "Couldn't disconnect.";
        }
    }

    Timer {
        id: pairingTimeout
        interval: 60000
        onTriggered: root.finishPairing("Pairing timed out.")
    }

    Process {
        id: serviceCheck
        command: ["busctl", "--system", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus",
            "org.freedesktop.DBus", "NameHasOwner", "s", "org.bluez"]
        stdout: StdioCollector { id: serviceReply }
        onExited: (code, status) => {
            root.serviceUnavailable = code !== 0 || status !== 0 || serviceReply.text.trim() !== "b true";
        }
    }

    Process {
        id: agent
        // bluetoothctl owns the BlueZ pairing agent for this one operation.
        command: ["script", "-qefc", "stty -echo; exec bluetoothctl --agent KeyboardDisplay", "/dev/null"]
        environment: ({ TERM: "dumb", LC_ALL: "C" })
        stdinEnabled: true

        stdout: StdioCollector {
            waitForEnd: false
            onDataChanged: root.handlePairingOutput(text)
        }

        onExited: {
            if (root.pairDevice)
                root.finishPairing("Bluetooth pairing agent closed.");
        }
    }
}
