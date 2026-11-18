pragma Singleton

import QtQuick
import Quickshell

Singleton {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string calendarDate: Qt.formatDateTime(clock.date, "dddd, MMMM d")
    readonly property string hours: Qt.formatDateTime(clock.date, "HH")
    readonly property string minutes: Qt.formatDateTime(clock.date, "mm")
}
