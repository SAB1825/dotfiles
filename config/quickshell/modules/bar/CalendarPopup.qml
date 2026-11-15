pragma ComponentBehavior: Bound
import QtQuick
import Ryu.Shell
import px.services.state
import "CalendarDate.js" as CalendarDate
import Ryu.Extraa
import px.services.theme

Item {
    id: root

    required property bool active

    readonly property int cellSize: 38
    readonly property var dayLabels: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    property date displayedDate: new Date()
    readonly property int year: displayedDate.getFullYear()
    readonly property int month: displayedDate.getMonth()
    readonly property int firstOffset: CalendarDate.firstWeekday(year, month)
    readonly property int monthLength: CalendarDate.daysInMonth(year, month)
    readonly property string title: CalendarDate.monthNames[month] + " " + year
    readonly property var savedEvents: StateService.get("gregorianCalendarEvents", {})

    property int selectedYear: 0
    property int selectedMonth: -1
    property int selectedDay: 0

    property int hoverDay: 0
    property string hoverTitle: ""
    property string hoverDesc: ""
    property real hoverX: 0
    property real hoverY: 0

    readonly property bool editorOpen: selectedDay > 0 && selectedMonth === month && selectedYear === year
    readonly property bool selectedHasEvent: editorOpen && eventDays[selectedDay] === true
    readonly property string selectedTitle: CalendarDate.monthNames[month] + " " + selectedDay + ", " + year

    readonly property var eventDays: {
        savedEvents;
        const out = {};
        for (let d = 1; d <= monthLength; d++) {
            const e = eventFor(year, month, d);
            if (e.title !== undefined)
                out[d] = true;
        }
        return out;
    }

    function loadSelected() {
        const e = eventFor(selectedYear, selectedMonth, selectedDay);
        titleInput.text = e.title ?? "";
        descInput.text = e.description ?? "";
    }

    function selectDay(d) {
        if (editorOpen && selectedDay === d) {
            selectedDay = 0;
            return;
        }
        selectedYear = year;
        selectedMonth = month;
        selectedDay = d;
        loadSelected();
    }

    function showHover(cell, d) {
        const e = eventFor(year, month, d);
        if (e.title === undefined) {
            hoverDay = 0;
            return;
        }
        const p = cell.mapToItem(root, 0, 0);
        hoverTitle = e.title;
        hoverDesc = e.description ?? "";
        hoverX = p.x + cell.width / 2;
        hoverY = p.y;
        hoverDay = d;
    }

    function hideHover(d) {
        if (hoverDay === d)
            hoverDay = 0;
    }

    function eventFor(y, m, d) {
        return savedEvents[CalendarDate.dateKey(y, m, d)] ?? {};
    }

    function save() {
        const title = titleInput.text.trim();
        if (title === "") return;
        const next = Object.assign({}, savedEvents);
        next[CalendarDate.dateKey(selectedYear, selectedMonth, selectedDay)] = {
            title: title, description: descInput.text.trim()
        };
        StateService.set("gregorianCalendarEvents", next);
    }

    function remove() {
        const next = Object.assign({}, savedEvents);
        delete next[CalendarDate.dateKey(selectedYear, selectedMonth, selectedDay)];
        StateService.set("gregorianCalendarEvents", next);
        titleInput.text = "";
        descInput.text = "";
    }

    function moveMonth(delta) {
        displayedDate = CalendarDate.shiftMonth(displayedDate, delta);
        selectedDay = 0;
        hoverDay = 0;
    }

    function setToday() {
        displayedDate = new Date();
        selectedDay = 0;
        hoverDay = 0;
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    onActiveChanged: setToday()

    anchors.centerIn: parent
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
    visible: active

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            root.hoverDay = 0;
            wheel.angleDelta.y > 0 ? root.moveMonth(-1) : root.moveMonth(1);
        }
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: root.cellSize * 7
            height: root.cellSize

            Rectangle {
                width: root.cellSize
                height: root.cellSize
                radius: height / 2
                opacity: 1
                color: prevArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                Text {
                    font.family: "CaskaydiaCove NF"
                    anchors.centerIn: parent
                    text: "<"
                    font.pixelSize: 22
                    font.bold: true
                    color: Theme.onSurfaceVariantColor
                }
                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.moveMonth(-1)
                }
            }

            Text {

                font.family: "CaskaydiaCove NF"
                anchors.centerIn: parent
                text: root.title
                font.pixelSize: 16
                font.bold: true
                color: Theme.primary
            }

            Rectangle {
                anchors.right: parent.right
                width: root.cellSize
                height: root.cellSize
                radius: height / 2
                opacity: 1
                color: nextArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                Text {
                    font.family: "CaskaydiaCove NF"
                    anchors.centerIn: parent
                    text: ">"
                    font.pixelSize: 22
                    font.bold: true
                    color: Theme.onSurfaceVariantColor
                }
                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.moveMonth(1)
                }
            }
        }

        Row {
            Repeater {
                model: root.dayLabels
                Item {
                    id: label
                    required property string modelData
                    required property int index
                    width: root.cellSize
                    height: 24
                    Text {
                        font.family: "CaskaydiaCove NF"
                        anchors.centerIn: parent
                        text: label.modelData
                        font.pixelSize: 13
                        font.bold: true
                        color: label.index === 6 ? Theme.error : Theme.onSurfaceVariantColor
                        opacity: 0.7
                    }
                }
            }
        }

        Grid {
            columns: 7
            Repeater {
                model: 42
                Item {
                    id: cell
                    required property int index

                    readonly property int dayNumber: index - root.firstOffset + 1
                    readonly property bool valid: dayNumber >= 1 && dayNumber <= root.monthLength
                    readonly property bool isToday: valid && root.year === clock.date.getFullYear() && root.month === clock.date.getMonth() && dayNumber === clock.date.getDate()
                    readonly property bool isSaturday: index % 7 === 6
                    readonly property bool isSelected: valid && root.editorOpen && root.selectedDay === dayNumber
                    readonly property bool hasEvent: valid && root.eventDays[dayNumber] === true

                    width: root.cellSize
                    height: root.cellSize

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cellSize - 4
                        height: width
                        radius: 10
                        color: cell.isToday ? Theme.primary : (cellArea.containsMouse && cell.valid ? Theme.surfaceContainerHighest : "transparent")
                        border.width: cell.isSelected && !cell.isToday ? 2 : 0
                        border.color: Theme.primary
                    }
                    Text {
                        font.family: "CaskaydiaCove NF"
                        anchors.centerIn: parent
                        visible: cell.valid
                        text: cell.dayNumber
                        font.pixelSize: 15
                        font.bold: cell.isToday || cell.isSelected
                        color: cell.isToday ? Theme.onPrimaryColor : cell.isSaturday ? Theme.error : Theme.onSurfaceVariantColor
                    }
                    Rectangle {
                        visible: cell.hasEvent
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height - 9
                        width: 4
                        height: 4
                        radius: 2
                        color: cell.isToday ? Theme.onPrimaryColor : Theme.primary
                    }
                    MouseArea {
                        id: cellArea
                        anchors.fill: parent
                        enabled: cell.valid
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectDay(cell.dayNumber)
                        onContainsMouseChanged: {
                            if (containsMouse)
                                root.showHover(cell, cell.dayNumber);
                            else
                                root.hideHover(cell.dayNumber);
                        }
                    }
                }
            }
        }

        Column {
            width: root.cellSize * 7
            spacing: 8
            visible: root.editorOpen

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outlineVariant
            }

            Row {
                width: parent.width
                spacing: 8

                Text {

                    font.family: "CaskaydiaCove NF"
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.selectedTitle
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
                Text {
                    font.family: "CaskaydiaCove NF"
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.selectedHasEvent
                    text: "saved"
                    font.pixelSize: 11
                    color: Theme.onSurfaceVariantColor
                    opacity: 0.55
                }
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: 12
                color: Theme.surfaceContainerHighest
                border.width: 1
                border.color: titleInput.activeFocus ? Theme.primary : Theme.outlineVariant

                TextInput {

                    font.family: "CaskaydiaCove NF"
                    id: titleInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    maximumLength: 80
                    font.pixelSize: 14
                    color: Theme.onSurfaceVariantColor
                    selectionColor: Theme.primaryContainer
                    selectedTextColor: Theme.onSurfaceVariantColor
                    onAccepted: descInput.forceActiveFocus()
                    Keys.onEscapePressed: root.forceActiveFocus()

                    Text {

                        font.family: "CaskaydiaCove NF"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: titleInput.text === ""
                        text: "Title"
                        font.pixelSize: 14
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.5
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 76
                radius: 12
                color: Theme.surfaceContainerHighest
                border.width: 1
                border.color: descInput.activeFocus ? Theme.primary : Theme.outlineVariant

                TextEdit {
                    id: descInput
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    wrapMode: TextEdit.Wrap
                    font.pixelSize: 13
                    color: Theme.onSurfaceVariantColor
                    selectionColor: Theme.primaryContainer
                    selectedTextColor: Theme.onSurfaceVariantColor
                    Keys.onEscapePressed: root.forceActiveFocus()

                    Text {

                        font.family: "CaskaydiaCove NF"
                        visible: descInput.text === ""
                        text: "Description"
                        font.pixelSize: 13
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.5
                    }
                }
            }

            Row {
                spacing: 8
                layoutDirection: Qt.RightToLeft
                width: parent.width

                MaterialIconButton {
                    enabled: titleInput.text.trim() !== ""
                    type: MaterialIconButton.Tonal
                    sizeStyle: MaterialIconButton.Small
                    widthStyle: MaterialIconButton.Wide
                    iconText: "\uf00c"
                    color: Theme.primary
                    iconColor: Theme.onPrimaryColor
                    onClicked: root.save()
                }

                MaterialIconButton {
                    visible: root.selectedHasEvent
                    type: MaterialIconButton.Tonal
                    sizeStyle: MaterialIconButton.Small
                    iconText: "\uf1f8"
                    iconSize: 18
                    color: Theme.surfaceContainerHighest
                    iconColor: Theme.error
                    onClicked: root.remove()
                }
            }
        }
    }

    Rectangle {
        id: tip
        z: 10
        visible: opacity > 0.01
        opacity: root.hoverDay > 0 ? 1 : 0
        width: 220
        height: tipCol.implicitHeight + 20
        radius: 12
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: Theme.outlineVariant
        x: Math.max(0, Math.min(root.hoverX - width / 2, root.width - width))
        y: root.hoverY - height - 4 >= 0 ? root.hoverY - height - 4 : root.hoverY + root.cellSize + 4

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        Column {
            id: tipCol
            x: 10
            y: 10
            width: parent.width - 20
            spacing: 4

            Text {

                font.family: "CaskaydiaCove NF"
                width: parent.width
                text: root.hoverTitle
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.primary
            }
            Text {
                font.family: "CaskaydiaCove NF"
                width: parent.width
                visible: text !== ""
                text: root.hoverDesc
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                font.pixelSize: 12
                color: Theme.onSurfaceVariantColor
                opacity: 0.85
            }
        }
    }
}
