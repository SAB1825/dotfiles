pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/modules/clipboard/clipboard.sh"
    readonly property bool copying: copyProcess.running
    property var entries: []
    property bool loaded: false
    property string error: ""
    property string lastListing: ""

    signal copied()

    function start() {
        watcher.running = true;
    }

    function refresh() {
        if (!listProcess.running)
            listProcess.running = true;
    }

    function copy(entry) {
        if (!entry || copying)
            return;

        error = "";
        copyProcess.exec(["bash", script, "copy", entry.id, entry.mimeType]);
    }

    Process {
        id: watcher
        command: ["wl-paste", "--watch", "bash", root.script, "store"]
    }

    Process {
        id: listProcess
        command: ["bash", root.script, "list"]
        stdout: StdioCollector { id: listing }

        onExited: (exitCode, exitStatus) => {
            root.loaded = true;
            if (exitCode !== 0 || exitStatus !== 0) {
                if (!root.error)
                    root.error = "Couldn't read clipboard history";
                return;
            }

            if (root.error === "Couldn't read clipboard history")
                root.error = "";
            if (listing.text === root.lastListing)
                return;
            root.lastListing = listing.text;

            const entries = [];
            for (const line of listing.text.split("\n")) {
                const split = line.indexOf("\t");
                const id = line.slice(0, split);
                if (split < 1 || !/^\d+$/.test(id))
                    continue;

                const preview = line.slice(split + 1);
                const binary = /^\[\[ binary data (.+?) ?\]\]$/.exec(preview);
                const image = binary && /^(.+) (png|jpe?g|gif|webp|bmp|tiff?) (\d+x\d+)$/i.exec(binary[1]);
                let format = image ? image[2].toLowerCase() : "";
                if (format === "jpg")
                    format = "jpeg";
                if (format === "tif")
                    format = "tiff";
                entries.push({
                    id: id,
                    title: image ? "Image" : binary ? "Binary data" : preview || "Text",
                    detail: image ? image[2] + " · " + image[3] + " · " + image[1] : binary ? binary[1] : "",
                    format: format,
                    mimeType: binary ? "" : "text/plain;charset=utf-8"
                });
            }
            root.entries = entries;
        }
    }

    Process {
        id: copyProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && exitStatus === 0) {
                root.copied();
                root.refresh();
            } else {
                root.error = "Couldn't copy this entry";
            }
        }
    }
}
