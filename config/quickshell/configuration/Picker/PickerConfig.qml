pragma Singleton
import QtQuick
import Ryu.Shell
import Ryu.Io
import px.services.paths

QtObject {
    id: root

    property bool open: false
    property int tab: 0

    readonly property string resultPath: PathService.runtime + "/phoenix-picker-result"

    readonly property var screenItems: {
        const screens = Screens.list;
        return screens.map(s => ({
                    key: "s:" + s.name,
                    label: s.name + "  ·  " + s.size.width + "x" + s.size.height,
                    kind: "screen",
                    target: s.name,
                    source: s
                }));
    }

    // Window capture identifiers are compositor protocol handles, not niri IPC IDs.
    // Use the existing GNOME portal chooser for window sharing.
    readonly property var windowItems: []

    property Process writer: Process {}

    function toggle() {
        if (open)
            cancel();
        else
            show();
    }

    function show() {
        tab = 0;
        open = true;
    }

    function pick(kind, target) {
        finish((kind === "window" ? "Window: " : "Monitor: ") + target);
    }

    function cancel() {
        finish("");
    }

    function finish(text) {
        if (!open)
            return;
        open = false;
        root.writer.command = ["sh", "-c", '[ -p "$2" ] && printf "%s" "$1" | timeout 3 tee "$2" >/dev/null', "sh", text, root.resultPath];
        root.writer.running = true;
    }
}
