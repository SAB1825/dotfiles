pragma Singleton
import QtQuick
import Ryu.Io

QtObject {
    id: root
    property bool connected: false
    property var workspaces: []
    property var windows: []
    property var outputs: ({})
    property string focusedOutput: ""

    function accept(line) {
        try {
            const state = JSON.parse(line);
            connected = state.connected;
            workspaces = state.workspaces;
            windows = state.windows;
            outputs = state.outputs;
            focusedOutput = state.focusedOutput?.name ?? "";
        } catch (error) {
            console.warn("niri state:", error);
        }
    }
    function forScreen(screen) {
        return workspaces.filter(w => w.output === screen.name).sort((a, b) => a.idx - b.idx);
    }
    function focusWorkspace(id) {
        // Use the stable ID: workspace indexes are local to each output.
        Exec.detached(["python3", Qt.resolvedUrl("../../scripts/niri-state.py").toString().replace("file://", ""), "--focus-workspace", String(id)]);
    }
    function focusWindow(id) {
        Exec.detached(["niri", "msg", "action", "focus-window", "--id", String(id)]);
    }
    function overview() { Exec.detached(["niri", "msg", "action", "toggle-overview"]); }
    property Process watcher: Process {
        command: ["python3", Qt.resolvedUrl("../../scripts/niri-state.py").toString().replace("file://", "")]
        running: true
        stdout: SplitParser { onRead: data => root.accept(data) }
        onExited: root.retry.restart()
        onFailed: message => root.retry.restart()
    }
    property Timer retry: Timer {
        interval: 2000
        onTriggered: root.watcher.running = true
    }
}
