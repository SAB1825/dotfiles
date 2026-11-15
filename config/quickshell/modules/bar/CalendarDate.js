.pragma library

var monthNames = ["January", "February", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December"];

function daysInMonth(year, month) {
    return new Date(year, month + 1, 0).getDate();
}

function firstWeekday(year, month) {
    return new Date(year, month, 1).getDay();
}

function shiftMonth(date, delta) {
    return new Date(date.getFullYear(), date.getMonth() + delta, 1);
}

function dateKey(year, month, day) {
    return year + "-" + String(month + 1).padStart(2, "0") + "-" + String(day).padStart(2, "0");
}
