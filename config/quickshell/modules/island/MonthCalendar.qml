pragma ComponentBehavior: Bound

import QtQuick
import "../theme"

Rectangle {
    id: calendar

    required property string fontFamily
    required property date today
    readonly property var locale: Qt.locale()
    property date monthStart: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property int firstDayOffset: (monthStart.getDay() - locale.firstDayOfWeek + 7) % 7
    readonly property bool currentMonth: monthStart.getFullYear() === today.getFullYear()
        && monthStart.getMonth() === today.getMonth()

    function showCurrentMonth() {
        monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    }

    function moveMonth(offset) {
        monthStart = new Date(monthStart.getFullYear(), monthStart.getMonth() + offset, 1);
    }

    onVisibleChanged: {
        if (visible)
            showCurrentMonth();
    }

    implicitHeight: content.implicitHeight + 32
    radius: 18
    color: Monochrome.background
    border.color: Monochrome.outline

    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: content

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 16
        }
        spacing: 12

        Item {
            width: parent.width
            height: 32

            Text {
                anchors.left: parent.left
                anchors.right: navigation.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(calendar.monthStart, "MMMM yyyy")
                elide: Text.ElideRight
                color: Monochrome.foreground
                font.family: calendar.fontFamily
                font.weight: Typography.weight
                font.pixelSize: 17
            }

            Row {
                id: navigation
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                IslandMenuButton {
                    text: "Today"
                    font.family: calendar.fontFamily
                    onClicked: calendar.showCurrentMonth()
                }

                IslandMenuButton {
                    text: "‹"
                    font.family: calendar.fontFamily
                    Accessible.name: "Previous month"
                    onClicked: calendar.moveMonth(-1)
                }

                IslandMenuButton {
                    text: "›"
                    font.family: calendar.fontFamily
                    Accessible.name: "Next month"
                    onClicked: calendar.moveMonth(1)
                }
            }
        }

        Grid {
            id: dates
            width: parent.width
            columns: 7
            readonly property real cellWidth: width / columns

            Repeater {
                model: 7

                Text {
                    required property int index
                    width: dates.cellWidth
                    height: 26
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: calendar.locale.standaloneDayName(
                        (calendar.locale.firstDayOfWeek + index - 1) % 7 + 1, Locale.ShortFormat)
                    color: Monochrome.muted
                    font.family: calendar.fontFamily
                    font.weight: Typography.weight
                    font.pixelSize: 11
                }
            }

            Repeater {
                model: 42

                Item {
                    id: cell
                    required property int index
                    readonly property date day: new Date(calendar.monthStart.getFullYear(),
                        calendar.monthStart.getMonth(), index - calendar.firstDayOffset + 1)
                    readonly property bool inMonth: day.getMonth() === calendar.monthStart.getMonth()
                    readonly property bool isToday: inMonth && calendar.currentMonth
                        && day.getDate() === calendar.today.getDate()

                    width: dates.cellWidth
                    height: 36

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(cell.width, 30)
                        height: 30
                        radius: 9
                        color: Monochrome.accent
                        visible: cell.isToday
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.day.getDate()
                        color: cell.isToday ? Monochrome.accentText : cell.inMonth ? Monochrome.foreground : Monochrome.muted
                        opacity: cell.inMonth ? 1 : 0.72
                        font.family: calendar.fontFamily
                        font.weight: Typography.weight
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
