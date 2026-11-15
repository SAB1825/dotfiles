pragma ComponentBehavior: Bound
import QtQuick
import px.services.theme
import px.services.github

Item {
    id: root
    required property bool active
    property var hoveredDay: null
    readonly property int tile: 5
    readonly property int gap: 2
    readonly property var calendarCells: {
        const days = GitHubService.days;
        if (!days.length) return [];
        const first = new Date(days[0].date + "T00:00:00Z").getUTCDay();
        const cells = new Array(first).fill(null).concat(days);
        while (cells.length % 7) cells.push(null);
        return cells;
    }
    readonly property int weeks: calendarCells.length / 7
    readonly property var tones: [Theme.surfaceContainerHighest,
        Qt.tint(Theme.surfaceContainerHighest, Qt.alpha(Theme.primary, 0.25)),
        Qt.tint(Theme.surfaceContainerHighest, Qt.alpha(Theme.primary, 0.50)),
        Qt.tint(Theme.surfaceContainerHighest, Qt.alpha(Theme.primary, 0.75)),
        Theme.primary]
    implicitWidth: 420
    implicitHeight: column.implicitHeight
    visible: active
    onActiveChanged: if (active) GitHubService.refresh(false)

    component ActionButton: Rectangle {
        id: button
        property string label: ""
        property bool primary: false
        signal clicked()
        width: buttonText.implicitWidth + 24
        height: 28
        radius: 8
        opacity: enabled ? 1 : 0.5
        color: primary ? Theme.primary : buttonMouse.containsMouse ? Theme.primaryContainer : Theme.surfaceContainerHighest
        Text {
            id: buttonText
            anchors.centerIn: parent
            text: button.label
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: button.primary ? Theme.onPrimaryColor : Theme.onSurfaceVariantColor
        }
        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    function monthLabel(week) {
        const cell = calendarCells[week * 7] ?? (week === 0 ? GitHubService.days[0] : null);
        if (!cell) return "";
        const month = new Date(cell.date + "T00:00:00Z").getUTCMonth();
        const previous = week > 0 ? calendarCells[(week - 1) * 7] ?? GitHubService.days[0] : null;
        if (previous && month === new Date(previous.date + "T00:00:00Z").getUTCMonth()) return "";
        return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][month];
    }
    Column {
        id: column
        width: root.implicitWidth
        spacing: 7
        Text {
            text: "GitHub  /  @" + GitHubService.username
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            color: Theme.primary
        }
        Text {
            text: GitHubService.today === null ? (GitHubService.busy ? "Loading…" : "Commit count unavailable") : GitHubService.today + (GitHubService.today === 1 ? " commit today" : " commits today")
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            font.bold: true
            color: Theme.onBackgroundColor
        }
        Text {
            text: "CONTRIBUTIONS · PAST YEAR"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Theme.onSurfaceVariantColor
        }
        Column {
            width: parent.width
            spacing: 5
            visible: root.weeks > 0
            Row {
                x: 34
                Repeater {
                    model: root.weeks
                    Item {
                        required property int index
                        width: root.tile + root.gap
                        height: 16
                        Text {
                            text: root.monthLabel(parent.index)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Theme.onSurfaceVariantColor
                        }
                    }
                }
            }
            Row {
                spacing: 6
                Column {
                    width: 28
                    Repeater {
                        model: ["", "Mon", "", "Wed", "", "Fri", ""]
                        Item {
                            required property string modelData
                            width: 28
                            height: root.tile + root.gap
                            Text {
                                text: parent.modelData
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: Theme.onSurfaceVariantColor
                            }
                        }
                    }
                }
                Grid {
                    rows: 7
                    flow: Grid.TopToBottom
                    spacing: root.gap
                    Repeater {
                        model: root.calendarCells
                        Rectangle {
                            id: day
                            required property var modelData
                            width: root.tile
                            height: root.tile
                            radius: 2
                            color: modelData ? root.tones[modelData.level] : "transparent"
                            border.width: hover.hovered ? 1 : 0
                            border.color: Theme.onBackgroundColor
                            HoverHandler {
                                id: hover
                                enabled: day.modelData !== null
                                onHoveredChanged: root.hoveredDay = hovered ? day.modelData : null
                            }
                        }
                    }
                }
            }
            Row {
                spacing: 4
                Text {
                    text: "Less"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Theme.onSurfaceVariantColor
                }
                Repeater {
                    model: root.tones
                    Rectangle {
                        required property string modelData
                        width: root.tile
                        height: root.tile
                        radius: 2
                        color: modelData
                    }
                }
                Text {
                    text: "More"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Theme.onSurfaceVariantColor
                }
            }
        }
        Text {
            width: parent.width
            text: root.hoveredDay ? root.hoveredDay.date + " · " + (root.hoveredDay.count === null ? "activity level " + root.hoveredDay.level : root.hoveredDay.count + " contributions") : "Hover the calendar for contribution details"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Theme.onSurfaceVariantColor
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: [GitHubService.error, GitHubService.result.calendarError ?? "", GitHubService.result.commitsError ?? ""].filter(x => x !== "").join("\n")
            wrapMode: Text.Wrap
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Theme.error
        }
        Text {
            text: "RECENT COMMITS · TODAY (UTC)"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            color: Theme.primary
        }
        Text {
            visible: GitHubService.today === 0
            text: "No public commits indexed for today yet."
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Theme.onSurfaceVariantColor
        }
        Flickable {
            width: parent.width
            height: Math.min(156, logs.implicitHeight)
            contentHeight: logs.implicitHeight
            contentWidth: width
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: logs
                width: parent.width
                spacing: 5
                Repeater {
                    model: GitHubService.recent
                    Rectangle {
                        id: row
                        required property var modelData
                        width: logs.width
                        height: 48
                        radius: 6
                        color: mouse.containsMouse ? Theme.primaryContainer : Theme.surfaceContainer
                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2
                            Text {
                                width: parent.width
                                text: row.modelData.title
                                elide: Text.ElideRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color: Theme.onSurfaceColor
                            }
                            Text {
                                width: parent.width
                                text: row.modelData.repo + " · " + row.modelData.sha
                                elide: Text.ElideRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: Theme.onSurfaceVariantColor
                            }
                        }
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GitHubService.openCommit(row.modelData.url)
                        }
                    }
                }
            }
        }
        Text {
            visible: GitHubService.today !== null && GitHubService.today > GitHubService.recent.length
            text: "Showing the latest " + GitHubService.recent.length + " commits from today."
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Theme.onSurfaceVariantColor
        }
        Row {
            spacing: 12
            ActionButton {
                label: GitHubService.busy ? "Refreshing…" : "Refresh"
                enabled: !GitHubService.busy
                primary: true
                onClicked: GitHubService.refresh(true)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (GitHubService.stale ? "Cached · " : "") + (GitHubService.result.updated ? Qt.formatDateTime(new Date(GitHubService.result.updated), "hh:mm") + " · " : "") + "auto · 5 min"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: Theme.onSurfaceVariantColor
            }
        }
    }
}
