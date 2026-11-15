pragma ComponentBehavior: Bound

import QtQuick
import px.services.theme
import px.services.niri

Item {
    id: root

    required property var screen
    property bool vertical: false

    readonly property var workspaceList: NiriService.forScreen(root.screen)
    readonly property int count: Math.max(5, workspaceList.length)
    readonly property int activeId: workspaceList.find(w => w.is_active)?.id ?? -1
    readonly property var occupied: new Set(NiriService.windows.map(w => w.workspace_id))

    implicitWidth: vertical ? strip.implicitHeight : strip.implicitWidth
    implicitHeight: vertical ? strip.implicitWidth : strip.implicitHeight

    function go(i) {
        NiriService.focusWorkspace(i);
    }

    Row {
        id: strip

        spacing: 5
        rotation: root.vertical ? 90 : 0
        transformOrigin: Item.TopLeft
        x: root.vertical ? strip.implicitHeight : 0

        Repeater {
            model: root.count

            Rectangle {
                id: pill

                required property int index
                readonly property int wsId: root.workspaceList[index]?.id ?? -1
                readonly property bool active: wsId >= 0 && wsId === root.activeId
                readonly property bool filled: root.occupied.has(wsId)

                width: active ? 45 : 10
                height: 10
                radius: height / 2
                color: filled ? Theme.primary : Theme.onBackgroundColor
                opacity: wsId >= 0 ? 1 : 0.35

                Behavior on width {
                    SpringAnimation {
                        spring: 3
                        damping: 0.25
                        epsilon: 0.25
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: pill.wsId >= 0
                    onClicked: root.go(pill.wsId)
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
