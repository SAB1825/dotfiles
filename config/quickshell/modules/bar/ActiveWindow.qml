import QtQuick
import px.services.niri
import px.services.theme

Item {
    id: root
    property bool vertical: false
    property real availableLength: 280
    readonly property var focusedWindow: NiriService.windows.find(window => window.is_focused) ?? null
    readonly property string title: focusedWindow ? (focusedWindow.title || focusedWindow.app_id || "Window") : "Desktop"
    readonly property real titleLength: Math.max(0, Math.min(280, availableLength))
    implicitWidth: vertical ? 40 : titleLength
    implicitHeight: vertical ? titleLength : 40
    clip: true

    Text {
        anchors.centerIn: parent
        width: root.titleLength
        rotation: root.vertical ? -90 : 0
        text: root.title
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: "CaskaydiaCove NF"
        font.pixelSize: 13
        font.weight: Font.Medium
        color: Theme.onSurfaceVariantColor
    }
}
