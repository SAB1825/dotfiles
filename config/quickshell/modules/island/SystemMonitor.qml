pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import "../theme"

Rectangle {
    id: monitor

    function format(value, unit) {
        return Number.isFinite(value) ? Math.round(value) + unit : "—";
    }

    width: measurements.width + 16
    height: 36
    radius: 14
    color: Monochrome.background

    Row {
        id: measurements

        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: [
                { label: "CPU", value: monitor.format(SystemStats.cpuUsage, "%") },
                { label: "MEM", value: monitor.format(SystemStats.memoryUsage, "%") },
                { label: "TMP", value: monitor.format(SystemStats.cpuTemperature, "°") }
            ]

            Row {
                id: metric
                required property var modelData
                spacing: 4

                Rectangle {
                    width: badge.implicitWidth + 8
                    height: 19
                    radius: 4
                    color: Monochrome.accent

                    Text {
                        id: badge
                        anchors.centerIn: parent
                        text: metric.modelData.label
                        font.family: Typography.family
                        font.weight: Typography.weight
                        font.pixelSize: 11
                        color: Monochrome.accentText
                    }
                }

                Text {
                    id: reading

                    anchors.verticalCenter: parent.verticalCenter
                    width: valueWidth.width
                    text: metric.modelData.value
                    horizontalAlignment: Text.AlignLeft
                    font.family: Typography.family
                    font.weight: Typography.weight
                    font.pixelSize: 12
                    color: Monochrome.foreground

                    TextMetrics {
                        id: valueWidth
                        font: reading.font
                        text: "100%"
                    }
                }
            }
        }
    }
}
