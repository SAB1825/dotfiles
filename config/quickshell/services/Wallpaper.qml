pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string directory: (Quickshell.env("HOME") ?? "") + "/Pictures/Wallpapers"
    readonly property string currentPath: activeProcess?.imagePath ?? ""
    readonly property bool busy: candidate !== null
    readonly property bool scanning: scan.running
    property var entries: []
    property string scanError: ""
    property string applyError: ""
    property string lastListing: ""
    property Process activeProcess: null
    property Process candidate: null

    signal applied(string path)

    function start() {
        state.reload();
    }

    function refresh() {
        if (!scan.running)
            scan.running = true;
    }

    function apply(path) {
        if (!path || busy)
            return;
        applyError = "";
        if (path === currentPath) {
            applied(path);
            return;
        }

        candidate = background.createObject(root, { imagePath: path });
        candidate.running = true;
        startupTimeout.restart();
    }

    function reject(process, message) {
        if (!process || process !== candidate)
            return;
        startupTimeout.stop();
        handoff.stop();
        candidate = null;
        applyError = message;
        process.destroy();
    }

    FileView {
        id: state
        path: Quickshell.stateDir + "/wallpaper.json"
        printErrors: false
        atomicWrites: true

        onLoaded: {
            if (root.activeProcess || root.busy)
                return;
            try {
                const path = JSON.parse(state.text());
                if (typeof path === "string" && path.startsWith(root.directory + "/"))
                    root.apply(path);
            } catch (error) {
                console.warn("Couldn't read saved wallpaper:", error);
            }
        }

        onSaveFailed: error => console.warn("Couldn't save wallpaper:", error)
    }

    Process {
        id: scan
        command: ["find", "-H", root.directory, "-type", "f", "(",
            "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png",
            "-o", "-iname", "*.webp", "-o", "-iname", "*.bmp", ")", "-print0"]
        stdout: StdioCollector { id: listing }

        onExited: (code, status) => {
            if (code !== 0 || status !== 0) {
                root.scanError = "Couldn't read ~/Pictures/Wallpapers";
                return;
            }
            root.scanError = "";
            if (root.lastListing === listing.text)
                return;
            root.lastListing = listing.text;
            const files = listing.text.split("\u0000").filter(Boolean);
            const entries = files.map(path => {
                const relative = path.slice(root.directory.length + 1);
                const slash = relative.lastIndexOf("/");
                return {
                    path: path,
                    url: "file://" + path.split("/").map(encodeURIComponent).join("/"),
                    name: relative.slice(slash + 1),
                    folder: slash < 0 ? "" : relative.slice(0, slash),
                    searchText: relative.toLowerCase()
                };
            });
            entries.sort((a, b) => a.name.localeCompare(b.name) || a.path.localeCompare(b.path));
            root.entries = entries;
        }
    }

    Timer {
        id: startupTimeout
        interval: 2500
        onTriggered: root.reject(root.candidate, "swaybg didn't start")
    }

    // swaybg has no readiness API. Give the replacement time to map its
    // background and keep the current child if the replacement exits or errors.
    Timer {
        id: handoff
        interval: 450

        onTriggered: {
            const next = root.candidate;
            if (!next || !next.running)
                return;
            const previous = root.activeProcess;
            root.activeProcess = next;
            root.candidate = null;
            state.setText(JSON.stringify(next.imagePath));
            if (previous)
                previous.destroy();
            root.applied(next.imagePath);
        }
    }

    Component {
        id: background

        Process {
            id: process
            required property string imagePath
            command: ["bash", "-c", "exec swaybg -m fill -i \"$1\"", "swaybg", imagePath]

            stderr: SplitParser {
                onRead: line => {
                    if (/Failed to (?:load|read) (?:background )?image/i.test(line))
                        root.reject(process, "swaybg couldn't load this wallpaper");
                }
            }

            onStarted: {
                if (process === root.candidate) {
                    startupTimeout.stop();
                    handoff.restart();
                }
            }

            onExited: {
                if (process === root.candidate) {
                    root.reject(process, "swaybg couldn't load this wallpaper");
                } else if (process === root.activeProcess) {
                    root.activeProcess = null;
                    root.applyError = "swaybg stopped";
                    process.destroy();
                }
            }
        }
    }
}
