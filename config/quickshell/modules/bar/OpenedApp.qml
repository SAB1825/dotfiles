pragma ComponentBehavior: Bound
import QtQuick
import Ryu.Io
import Ryu.Desktop
import px.services.niri
import Ryu.Ui
import px.services.theme

Grid {
    id: root
    property bool vertical: false
    property bool notched: false
    property real pushAmount: 6
    spacing: 2
    flow: vertical ? Grid.TopToBottom : Grid.LeftToRight
    columns: vertical ? 1 : Math.max(1, groups.length)
    property var hoveredCell: null
    property real lastM: 0
    property string lastAppId: ""
    readonly property var hoverGroup: groups.find(g => g.appId === lastAppId) ?? null
    readonly property int lastIndex: groups.findIndex(g => g.appId === lastAppId)
    onHoveredCellChanged: if (hoveredCell) {
        lastM = vertical ? hoveredCell.y : hoveredCell.x;
        lastAppId = hoveredCell.modelData.appId;
    }
    // Stable pins stay in place whether or not their windows are open.
    readonly property var pins: [
        {appId: "code-oss", name: "Code", icon: "com.visualstudio.code.oss", command: ["code-oss"], matches: ["code-oss", "code", "com.visualstudio.code.oss"]},
        {appId: "helium", name: "Helium", icon: "helium-browser", command: ["helium-browser"], matches: ["helium", "helium-browser"]},
        {appId: "kitty", name: "Kitty", icon: "kitty", command: ["kitty"], matches: ["kitty"]}
    ]
    readonly property var groups: pins.map(pin => ({
        appId: pin.appId,
        name: pin.name,
        command: pin.command,
        icon: pin.appId === "helium" ? "file:///opt/helium-browser-bin/product_logo_256.png" : DesktopIcons.path(pin.icon, "application-x-executable"),
        toplevels: NiriService.windows.filter(t => pin.matches.indexOf((t.app_id || "").toLowerCase()) >= 0)
            .map(t => ({id: t.id, title: t.title, activated: t.is_focused}))
    }))
    function activateGroup(group) {
        const items = group.toplevels;
        if (!items.length) {
            Exec.detached(group.command);
            return;
        }
        const current = items.findIndex(t => t.activated);
        NiriService.focusWindow(items[(current + 1) % items.length].id);
    }
    Repeater {
        model: ScriptModel {
            values: root.groups
            objectProp: "appId"
        }
        delegate: Rectangle {
            id: cell
            required property var modelData
            required property int index
            readonly property var instances: modelData.toplevels
            readonly property bool anyActive: instances.some(t => t.activated)
            readonly property real push: {
                if (!root.notched || root.lastIndex < 0 || index === root.lastIndex)
                    return 0;
                return index < root.lastIndex ? -root.pushAmount : root.pushAmount;
            }
            width: root.vertical ? 40 : 36
            height: root.vertical ? 36 : 40
            radius: height / 2
            color: hover.hovered ? Theme.surfaceContainerHighest : Theme.background
            scale: mouse.pressed ? 0.92 : hover.hovered ? 1.08 : 1
            Behavior on scale {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 150 } }
            transform: Translate {
                x: root.vertical ? 0 : cell.push
                y: root.vertical ? cell.push : 0
                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
            IconImage {
                anchors.centerIn: parent
                source: cell.modelData.icon
                implicitSize: 22
                opacity: cell.anyActive || hover.hovered ? 1 : 0.8
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                width: cell.anyActive ? 12 : 4
                height: 3
                radius: 2
                visible: cell.instances.length > 0
                color: cell.anyActive ? Theme.primary : Theme.onSurfaceVariantColor
                Behavior on width { NumberAnimation { duration: 160 } }
            }
            HoverHandler {
                id: hover
                onHoveredChanged: {
                    if (hovered)
                        root.hoveredCell = cell;
                    else if (root.hoveredCell === cell)
                        root.hoveredCell = null;
                }
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activateGroup(cell.modelData)
            }
        }
    }
}
