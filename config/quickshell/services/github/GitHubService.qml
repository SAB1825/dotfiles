pragma Singleton
import QtQuick
import Ryu.Io

QtObject {
    id: root
    readonly property string username: "SAB1825"
    property var result: ({})
    readonly property bool busy: fetcher.running
    readonly property var today: result.today ?? null
    readonly property var days: result.days ?? []
    readonly property var recent: result.recent ?? []
    readonly property string error: result.error ?? ""
    readonly property bool stale: result.stale ?? false
    readonly property string helper: Qt.resolvedUrl("../../scripts/github-commits.py").toString().replace("file://", "")

    function refresh(force) {
        if (fetcher.running) return;
        fetcher.command = ["python3", helper, "--username", username].concat(force ? ["--force"] : []);
        fetcher.running = true;
    }
    function openCommit(url) {
        if (url.startsWith("https://github.com/")) Exec.detached(["firefox", "--new-tab", url]);
    }
    property Process fetcher: Process {
        stdout: SplitParser {
            onRead: data => {
                try { root.result = JSON.parse(data); }
                catch (error) { root.result = {error: "Unable to read GitHub results.", stale: true}; }
            }
        }
        onFailed: message => root.result = {error: message, stale: true}
    }
    property Timer timer: Timer { interval: 300000; repeat: true; running: true; onTriggered: root.refresh(false) }
    property Timer midnight: Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: {
            if (root.result.date && root.result.date !== new Date().toISOString().slice(0, 10)) {
                root.result = ({});
                root.refresh(false);
            }
        }
    }
    Component.onCompleted: refresh(false)
}
