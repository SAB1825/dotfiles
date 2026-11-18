pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

Image {
    id: thumbnail

    required property var entry

    fillMode: Image.PreserveAspectCrop

    Process {
        command: ["bash", ClipboardHistory.script, "thumbnail", thumbnail.entry.id, thumbnail.entry.format]
        running: true
        stdout: StdioCollector { id: encoded }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && exitStatus === 0 && encoded.text.length)
                thumbnail.source = "data:image/png;base64," + encoded.text;
        }
    }
}
