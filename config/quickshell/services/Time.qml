pragma Singleton

import QtQuick
import Quickshell

Singleton {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date today: clock.date
    readonly property string calendarDate: Qt.formatDateTime(clock.date, "dddd, MMMM d")
    readonly property string menuDate: Qt.formatDateTime(clock.date, "ddd d MMM")
    readonly property string hours: Qt.formatDateTime(clock.date, "HH")
    readonly property string minutes: Qt.formatDateTime(clock.date, "mm")
}
