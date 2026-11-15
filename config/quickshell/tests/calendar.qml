import QtQml
import "../modules/bar/CalendarDate.js" as CalendarDate

QtObject {
    Component.onCompleted: {
        try {
            function check(value, message) { if (!value) throw new Error(message); }
            check(CalendarDate.daysInMonth(2024, 1) === 29, "Leap-year February");
            check(CalendarDate.daysInMonth(2026, 1) === 28, "Ordinary February");
            check(CalendarDate.daysInMonth(1900, 1) === 28, "Century leap-year exception");
            check(CalendarDate.daysInMonth(2000, 1) === 29, "400-year leap-year exception");
            check(CalendarDate.firstWeekday(2026, 10) === 0, "November 2026 starts Sunday");
            check(CalendarDate.firstWeekday(2026, 0) === 4, "January 2026 starts Thursday");
            const previous = CalendarDate.shiftMonth(new Date(2026, 0, 31), -1);
            check(previous.getFullYear() === 2025 && previous.getMonth() === 11, "Previous year navigation");
            const next = CalendarDate.shiftMonth(new Date(2026, 11, 31), 1);
            check(next.getFullYear() === 2027 && next.getMonth() === 0, "Next year navigation");
            check(CalendarDate.dateKey(2026, 0, 2) === "2026-01-02", "Full date event key");
            check(CalendarDate.dateKey(2026, 0, 2) !== CalendarDate.dateKey(2027, 0, 2), "Year-separated events");
            console.log("Gregorian calendar: 10 checks passed");
            Qt.exit(0);
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }
}
