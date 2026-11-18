pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool backendAvailable: Networking.backend === NetworkBackendType.NetworkManager
    readonly property var adapters: Networking.devices.values.filter(device => device.type === DeviceType.Wifi)
    readonly property var device: adapters.find(adapter => adapter.connected) ?? adapters[0] ?? null
    readonly property bool available: backendAvailable && !!device
    readonly property bool blocked: available && !Networking.wifiHardwareEnabled
    readonly property bool enabled: available && Networking.wifiEnabled
    readonly property var networks: (device?.networks.values ?? []).filter(network => network.name)
        .sort((a, b) => Number(b.connected) - Number(a.connected)
            || Number(b.known) - Number(a.known) || a.name.localeCompare(b.name))
    readonly property var connected: networks.find(network => network.connected) ?? null
    readonly property string status: !backendAvailable ? "NetworkManager unavailable"
        : !device ? "No Wi-Fi adapter" : blocked ? "Blocked" : !enabled ? "Off" : connected?.name ?? "On"

    property bool scanning: false
    property var pending: null
    property var retryNetwork: null
    property bool joining: false
    property string error: ""

    function toggle() {
        if (!available || blocked)
            return;
        error = "";
        retryNetwork = null;
        Networking.wifiEnabled = !enabled;
    }

    function usesPassword(network) {
        return [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(network.security);
    }

    function canJoinWithoutPassword(network) {
        return network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe;
    }

    function changeConnection(network, password) {
        if (!network || !enabled || blocked || pending || network.stateChanging)
            return;
        error = "";
        retryNetwork = null;
        joining = !network.connected;
        pending = network;
        deadline.restart();

        if (!joining)
            network.disconnect();
        else if (password)
            network.connectWithPsk(password);
        else
            network.connect();
    }

    function finish(message) {
        deadline.stop();
        pending = null;
        error = message;
    }

    Binding {
        target: root.device ?? null
        property: "scannerEnabled"
        when: !!root.device && root.scanning && root.enabled && !root.blocked
        value: true
    }

    Connections {
        target: root.pending ?? null

        function onConnectedChanged() {
            if (root.pending && root.pending.connected === root.joining)
                root.finish("");
        }

        function onConnectionFailed(reason) {
            const network = root.pending;
            if (network && root.joining && root.usesPassword(network)
                    && [ConnectionFailReason.NoSecrets, ConnectionFailReason.WifiAuthTimeout].includes(reason)) {
                root.retryNetwork = network;
                root.finish("Check the Wi-Fi password and try again.");
            } else {
                root.finish(root.joining ? "Couldn't join the network." : "Couldn't disconnect.");
            }
        }
    }

    Timer {
        id: deadline
        interval: 20000
        onTriggered: root.finish(root.joining ? "Connection timed out." : "Disconnect timed out.")
    }
}
