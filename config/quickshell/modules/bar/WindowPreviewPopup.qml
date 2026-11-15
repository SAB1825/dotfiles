pragma ComponentBehavior: Bound
import QtQuick
import Ryu.Extraa
import px.services.niri
import px.services.theme

Item {
    id: root
    required property bool active
    required property var group
    property real maxWidth: 800
    readonly property var windows: group?.toplevels ?? []
    implicitWidth: Math.min(maxWidth, 360)
    implicitHeight: list.implicitHeight
    visible: active
    Column {
        id: list
        width: root.implicitWidth
        spacing: 6
        Repeater {
            model: root.windows
            Rectangle {
                id: row
                required property var modelData
                width: list.width
                height: 48
                radius: 16
                color: mouse.containsMouse ? Theme.primaryContainer : Theme.surfaceContainer
                Text {
                    font.family: "CaskaydiaCove NF"
                    anchors.fill: parent
                    anchors.margins: 14
                    verticalAlignment: Text.AlignVCenter
                    text: row.modelData.title || root.group?.appId || "Window"
                    elide: Text.ElideRight
                    color: Theme.onSurfaceColor
                    font.pixelSize: 13
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NiriService.focusWindow(row.modelData.id)
                }
            }
        }
        MaterialButton {
            label: "Workspace overview"
            sizeStyle: MaterialButton.Small
            color: Theme.primary
            contentColor: Theme.onPrimaryColor
            onClicked: NiriService.overview()
        }
    }
}
