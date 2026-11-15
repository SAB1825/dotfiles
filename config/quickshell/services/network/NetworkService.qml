pragma Singleton
import QtQuick
import Ryu.Io

QtObject {
    id: root
    readonly property var client: root
    property bool available: false
    property bool powered: false
    property bool syncing: false
    property bool scanning: false
    property bool connecting: false
    property string deviceName: ""
    property string connectedSsid: ""
    property string state: ""
    property string message: ""
    property var networks: []
    property var knownNetworks: []
    property var pendingAction: ({})
    readonly property bool busy: scanning || connecting || action.running
    readonly property string statusText: !available ? "NetworkManager unavailable" : !powered ? "Off" : connectedSsid || state
    readonly property bool requestPending: false
    readonly property string requestKind: ""
    readonly property string requestNetwork: ""
    readonly property string requestUser: ""
    readonly property string helper: Qt.resolvedUrl("../../scripts/network.py").toString().replace("file://", "")
    function typeLabel(t) { return t === "open" ? "Open" : t === "8021x" ? "Enterprise" : "WPA"; }
    function refresh() { if (!poll.running && !action.running) poll.running = true; }
    function run(data) {
        if (action.running) return;
        pendingAction = data;
        message = "";
        action.running = true;
    }
    function scan() { if (!action.running) { scanning = true; run({op: "scan"}); } }
    function scanIfStale() { refresh(); }
    function connectTo(path, password, user) {
        if (action.running) return;
        const network = networks.find(n => n.path === path);
        if (network?.type === "8021x") {
            Exec.detached(["nm-connection-editor"]);
            message = "Configure the enterprise network in Connections.";
            return;
        }
        connecting = true;
        run({op: "connect", path: path, password: password, device: deviceName});
    }
    function disconnectNetwork() { run({op: "disconnect", device: deviceName}); }
    function editConnections() { Exec.detached(["nm-connection-editor"]); }
    function forget(path) { run({op: "forget", path: path}); }
    function setAutoConnect(path, on) { run({op: "auto", path: path, on: on}); }
    function cancelRequest() {}
    function submitCredentials(user, password) {}
    function submitPassphrase(password) {}
    onPoweredChanged: if (!syncing) run({op: "radio", on: powered})
    property Process poll: Process {
        command: ["python3", root.helper]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const d = JSON.parse(data);
                    if (d.error) { root.available = false; root.message = d.error; return; }
                    root.syncing = true;
                    root.available = d.available;
                    root.powered = d.powered;
                    root.deviceName = d.deviceName;
                    root.connectedSsid = d.connectedSsid;
                    root.state = d.state;
                    root.networks = d.networks;
                    root.knownNetworks = d.knownNetworks;
                    root.syncing = false;
                } catch (error) { root.syncing = false; console.warn("NetworkManager:", error); }
            }
        }
    }
    property Process action: Process {
        command: ["python3", root.helper, "action"]
        stdinEnabled: true
        onStarted: root.action.write(JSON.stringify(root.pendingAction) + "\n")
        stdout: SplitParser {
            onRead: data => {
                try { root.message = JSON.parse(data).error ?? ""; }
                catch (error) { console.warn(error); }
            }
        }
        onExited: code => {
            root.pendingAction = ({});
            root.connecting = false;
            root.scanning = false;
            root.refresh();
        }
        onFailed: message => {
            root.message = message;
            root.pendingAction = ({});
            root.connecting = false;
            root.scanning = false;
        }
    }
    property Timer timer: Timer { interval: 5000; repeat: true; running: true; onTriggered: root.refresh() }
}
