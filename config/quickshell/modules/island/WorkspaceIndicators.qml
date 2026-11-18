pragma ComponentBehavior: Bound

import QtQuick

Row {
    id: root

    required property var workspaces

    spacing: 6

    Repeater {
        model: root.workspaces.length

        delegate: Rectangle {
            required property int index
            readonly property var workspace: root.workspaces[index]

            width: workspace?.is_active ? 22 : 8
            height: 8
            radius: height / 2
            color: "#ffffff"
            opacity: workspace?.is_active ? 1 : workspace?.active_window_id != null ? 0.55 : 0.28

            Behavior on width {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 160 }
            }
        }
    }
}
