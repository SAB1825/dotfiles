import QtQuick
import px.services.theme
import px.services.github

Rectangle {
    id: root
    property bool open: false
    property bool vertical: false
    readonly property bool hovered: hover.hovered
    implicitWidth: vertical ? 40 : Math.max(60, content.implicitWidth + 20)
    implicitHeight: 40
    radius: 12
    color: open || hovered ? Theme.surfaceContainerHighest : Theme.background
    HoverHandler { id: hover }
    Row {
        id: content
        anchors.centerIn: parent
        spacing: 7
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf09b"
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 20
            color: Theme.primary
        }
        Text {
            visible: !root.vertical
            anchors.verticalCenter: parent.verticalCenter
            text: GitHubService.today === null ? (GitHubService.busy ? "…" : "–") : String(GitHubService.today)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true
            color: Theme.onSurfaceColor
        }
    }
}
