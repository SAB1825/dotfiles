import QtQuick
import px.services.theme
import px.services.github

Rectangle {
    id: root
    property bool open: false
    readonly property bool hovered: hover.hovered
    implicitWidth: 40
    implicitHeight: 40
    radius: height / 2
    color: Theme.background
    HoverHandler { id: hover }
    Text {
        anchors.centerIn: parent
        text: "\uf09b"
        font.family: "CaskaydiaCove NF"
        font.pixelSize: 24
        color: root.open || (GitHubService.today ?? 0) > 0 ? Theme.primary : Theme.onSurfaceVariantColor
    }
    Rectangle {
        visible: GitHubService.today !== null && GitHubService.today > 0
        anchors.right: parent.right
        anchors.top: parent.top
        width: Math.max(15, count.implicitWidth + 6)
        height: 15
        radius: 7
        color: Theme.primary
        Text {
            id: count
            anchors.centerIn: parent
            text: GitHubService.today > 99 ? "99+" : String(GitHubService.today ?? "")
            font.family: "CaskaydiaCove NF"
            font.pixelSize: 9
            color: Theme.onPrimaryColor
        }
    }
}
