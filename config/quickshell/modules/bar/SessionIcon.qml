import QtQuick

Canvas {
    id: root
    property color strokeColor: "white"
    implicitWidth: 24
    implicitHeight: 24
    antialiasing: true
    onStrokeColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 24, height / 24);
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.arc(12, 13, 8, -Math.PI / 2 + 0.65, Math.PI * 1.5 - 0.65);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(12, 2);
        ctx.lineTo(12, 12);
        ctx.stroke();
    }
}
