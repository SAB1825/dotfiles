pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int bars: 16

    property var levels: Array(bars).fill(0)
    property real total: 0

    Process {
        id: proc
        command: ["cava", "-p", Quickshell.shellDir + "/services/cava.conf"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const parts = data.split(";");
                if (parts.length > 1 && parts[parts.length - 1] === "")
                    parts.pop();
                if (parts.length > 1 && parts.length !== root.bars)
                    root.bars = parts.length;
                const out = [];
                var totalOut = 0;
                let changed = root.levels.length !== root.bars;
                for (let i = 0; i < root.bars; i++) {
                    const v = parseInt(parts[i], 10);
                    const value = isNaN(v) ? 0 : Math.max(0, Math.min(1, v / 100));
                    out.push(value);
                    totalOut += value;
                    changed = changed || value !== root.levels[i];
                }
                if (changed) {
                    root.levels = out;
                    root.total = totalOut;
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.levels = Array(root.bars).fill(0);
                root.total = 0;
            }
        }
    }
}
