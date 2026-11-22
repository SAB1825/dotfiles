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
    readonly property var paletteColors: palette.roles
    property var entries: []
    property string scanError: ""
    property string applyError: ""
    property string lastListing: ""
    property Process activeProcess: null
    property Process candidate: null

    signal applied(string path)

    onApplied: path => root.generatePalette(path)

    function generatePalette(path: string): void {
        if (!path || matugen.running)
            return;
        matugen.imagePath = path;
        matugen.running = true;
    }

    function start() {
        palette.reload();
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

    FileView {
        id: palette
        property var roles: ({})

        function readColors(contents) {
            try {
                const next = JSON.parse(contents)?.colors;
                if (!/^#[0-9a-f]{6}$/i.test(next?.primary?.dark?.color ?? ""))
                    return false;
                palette.roles = next;
                return true;
            } catch (error) {
                return false;
            }
        }

        path: Quickshell.stateDir + "/wallpaper-colors.json"
        printErrors: false
        atomicWrites: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: readColors(text())
        onSaveFailed: error => console.warn("Couldn't save wallpaper colors:", error)
    }

    Process {
        id: matugen
        property string imagePath: ""
        command: ["matugen", "image", "--config", Quickshell.shellPath("services/matugen.toml"),
            "--dry-run", "--json", "hex", "--source-color-index", "0", "--include-image-in-json", "true", imagePath]
        stdout: StdioCollector { id: colors }
        stderr: StdioCollector { id: matugenErrors }

        onExited: (code, status) => {
            if (imagePath !== root.currentPath) {
                Qt.callLater(() => root.generatePalette(root.currentPath));
                return;
            }
            if (code !== 0 || status !== 0 || !palette.readColors(colors.text)) {
                console.warn("Couldn't generate wallpaper colors:", matugenErrors.text.trim() || "invalid Matugen output");
                return;
            }
            palette.setText(colors.text);
        }
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
