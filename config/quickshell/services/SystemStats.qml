pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property real cpuUsage: sample.cpuUsage
    readonly property real memoryUsage: sample.memoryUsage
    readonly property real cpuTemperature: sample.cpuTemperature

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!sample.running)
                sample.running = true;
        }
    }

    Process {
        id: sample

        property real cpuUsage: NaN
        property real memoryUsage: NaN
        property real cpuTemperature: NaN
        property real previousTotal: 0
        property real previousIdle: 0

        command: ["bash", Quickshell.shellPath("services/system-stats.sh")]
        stdout: StdioCollector { id: readings }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0)
                return;

            const fields = readings.text.trim().split("\t");
            if (fields.length < 4)
                return;

            const [total, idle, memoryTotal, memoryAvailable] = fields.map(Number);
            const totalDelta = total - previousTotal;
            const idleDelta = idle - previousIdle;
            if (previousTotal > 0 && totalDelta > 0)
                cpuUsage = Math.max(0, Math.min(100, 100 * (1 - idleDelta / totalDelta)));
            previousTotal = total;
            previousIdle = idle;
            memoryUsage = memoryTotal > 0 && memoryAvailable >= 0
                ? Math.max(0, Math.min(100, 100 * (1 - memoryAvailable / memoryTotal))) : NaN;
            cpuTemperature = fields.length === 5 ? Number(fields[4]) / 1000 : NaN;
        }
    }
}
