pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import px.services.theme
import px.configuration.Bar

Item {
    id: root

    property real radius
    property color colour
    property var screen
    property Item target: controls
    property bool notchOpen: false

    readonly property Item popupS: host
    readonly property Item hitbox: hit

    readonly property string edge: BarConfig.edge
    readonly property bool floating: BarConfig.floating
    readonly property bool horizontal: edge === "top" || edge === "bottom"
    readonly property bool lowFlat: edge === "bottom" || edge === "right"
    readonly property real length: horizontal ? width : height
    readonly property real thickness: horizontal ? height : width

    readonly property real notchPadding: 4
    readonly property real notchRadius: 18
    readonly property real notchRadiusBottom: 30
    readonly property real itemGap: 4
    readonly property real popupGap: 10

    readonly property real topLine: floating ? 0 : radius
    readonly property real edgePad: floating ? Math.max(itemGap + notchPadding, radius * 0.5) : itemGap + notchPadding
    readonly property real rightPad: edgePad

    readonly property real cc: floating ? thickness / 2 : (lowFlat ? thickness / 2 + radius / 2 : thickness / 2 - radius / 2)
    readonly property real attach: floating ? (lowFlat ? 0 : thickness) : (lowFlat ? radius : thickness - radius)

    readonly property var permanent: floating ? [] : [sessionButton, recordingIndicator]
    readonly property var popupLoaders: [githubLoader, controlsLoader, calendarLoader, previewLoader, mediaLoader, startLoader, wifiLoader, nightLoader, performanceLoader]
    readonly property var activeLoader: popupLoaders.find(l => l.owner === target) ?? null
    readonly property var activeContent: activeLoader ? activeLoader.item : null
    readonly property bool popupShown: notchOpen && activeLoader !== null
    readonly property bool pinned: popupShown && target === wifiButton && (activeContent?.pinned ?? false)

    readonly property Item hoveredItem: {
        if (github.visible && github.hovered)
            return github;
        if (controls.visible && controls.hovered)
            return controls;
        if (wifiButton.visible && wifiButton.hovered)
            return wifiButton;
        if (nightMode.visible && nightMode.hovered)
            return nightMode;
        if (powerProfile.visible && powerProfile.hovered)
            return powerProfile;
        if (dateSlot.visible && dateSlot.hovered)
            return datetime;
        if (openedApp.visible && openedApp.hoveredCell)
            return appSlot;
        if (sessionButton.visible && (sessionButton.hovered || sessionSlot.hovered))
            return sessionButton;
        if (startMenu.visible && (startMenu.hovered || startSlot.hovered))
            return startMenu;
        if (mediaButton.visible && (mediaButton.hovered || mediaSlot.hovered))
            return mediaButton;
        if (host.hovered)
            return target;
        return null;
    }

    readonly property var moduleItems: ({launcher: startMenu, workspaces: workspace, title: activeWindow, date: datetime,
        github: github, media: mediaButton, nightlight: nightMode, performance: powerProfile, wifi: wifiButton, controls: controls, battery: battery, power: sessionButton})
    function moduleLength(key) {
        if (!BarConfig.moduleEnabled(key)) return 0;
        return lenOf(moduleItems[key]);
    }
    function modulePosition(key, side) {
        const order = side === "left" ? BarConfig.leftOrder : BarConfig.rightOrder;
        const active = order.filter(k => BarConfig.moduleEnabled(k));
        let position = edgePad;
        if (side === "right") {
            position = length - rightPad;
            for (const k of active) position -= moduleLength(k) + itemGap;
            if (active.length) position += itemGap;
        }
        for (const k of active) {
            if (k === key) return position;
            position += moduleLength(k) + itemGap;
        }
        return position;
    }
    readonly property real mSessionSlot: modulePosition("power", "right")
    readonly property real mSessionClosed: mSessionSlot
    readonly property real mWorkspace: modulePosition("workspaces", "left")
    readonly property real mStartSlot: modulePosition("launcher", "left")
    readonly property real mStart: mStartSlot
    readonly property real mMediaSlot: modulePosition("media", "right")
    readonly property real mMedia: mMediaSlot
    readonly property real mApps: (length - lenOf(openedApp)) / 2
    readonly property real mBattery: modulePosition("battery", "right")
    readonly property real mDateSlot: modulePosition("date", "right")
    readonly property real mDate: mDateSlot
    readonly property real mWifiSlot: modulePosition("wifi", "right")
    readonly property real mWifi: mWifiSlot
    readonly property real mControlsSlot: modulePosition("controls", "right")
    readonly property real mControls: mControlsSlot
    readonly property real mGitHubSlot: modulePosition("github", "right")
    readonly property real mGitHub: mGitHubSlot
    readonly property real mRec: modulePosition(BarConfig.rightOrder.find(k => BarConfig.moduleEnabled(k)), "right") - itemGap - lenOf(recordingIndicator)

    property Connections moduleSettings: Connections {
        target: BarConfig
        function onHiddenModulesChanged() { root.notchOpen = false; }
        function onLeftOrderChanged() { root.notchOpen = false; }
        function onRightOrderChanged() { root.notchOpen = false; }
    }

    readonly property real targetM: {
        if (target === datetime)
            return mDateSlot;
        if (target === wifiButton)
            return mWifiSlot;
        if (target === controls)
            return mControlsSlot;
        if (target === github)
            return mGitHubSlot;
        if (target === sessionButton)
            return mSessionSlot;
        if (target === startMenu)
            return mStartSlot;
        if (target === mediaButton)
            return mMediaSlot;
        return along(target);
    }

    readonly property real spanL: targetM - notchPadding
    readonly property real spanR: targetM + lenOf(target) + notchPadding

    property real notchProgress: notchOpen ? 1 : 0
    property real appOffset: openedApp.lastM
    property bool lagAnimated: true
    property real lagL: 0
    property real lagR: 0

    readonly property real l2: spanL + lagL
    readonly property real l3: spanR + lagR

    readonly property real crossSize: horizontal ? controls.height : controls.width
    readonly property real fullFloorY: floating ? Math.min(thickness / 2 + crossSize / 2 + notchPadding, thickness - 4) : Math.min(thickness / 2 + radius / 2 + crossSize / 2 + notchPadding, thickness)
    readonly property real permanentDepth: Math.max(0, fullFloorY - topLine)
    readonly property real depth: permanentDepth * notchProgress

    readonly property string outlinePath: buildPath()

    function lenOf(item) {
        return horizontal ? item.width : item.height;
    }

    function along(item) {
        return horizontal ? item.x : item.y;
    }

    function px(m, item) {
        return horizontal ? m : cc - item.width / 2;
    }

    function py(m, item) {
        return horizontal ? cc - item.height / 2 : m;
    }

    function pt(u, w) {
        switch (edge) {
        case "top":
            return u + " " + (thickness - w);
        case "left":
            return (thickness - w) + " " + u;
        case "right":
            return w + " " + u;
        }
        return u + " " + w;
    }

    function buildPath() {
        const R = radius;
        const W = length;
        const H = thickness;
        const T = topLine;
        const r = Math.max(0, Math.min(R, H / 2, W / 2));
        const inset = floating ? r : R;

        const cuts = [];
        for (const item of permanent) {
            if (!item.visible) continue;
            const d = permanentDepth * (item.cutProgress ?? 1);
            if (d < 0.5)
                continue;
            const s = along(item);
            cuts.push({
                l: s - notchPadding,
                r: s + lenOf(item) + notchPadding,
                d: d
            });
        }
        if (depth > 0.5 && permanent.indexOf(target) < 0)
            cuts.push({
                l: l2,
                r: l3,
                d: depth
            });
        cuts.sort((a, b) => a.l - b.l);

        const last = cuts.length - 1;
        const mergedL = !floating && R > 0 && last >= 0 && cuts[0].l < R;
        const mergedR = !floating && R > 0 && last >= 0 && cuts[last].r > W - R;

        let head;
        if (floating)
            head = `M ${pt(0, H - r)} L ${pt(0, r)} Q ${pt(0, 0)} ${pt(r, 0)}`;
        else if (mergedL)
            head = `M ${pt(0, H)} L ${pt(0, 0)}`;
        else
            head = `M ${pt(0, H)} L ${pt(0, 0)} Q ${pt(0, R)} ${pt(R, R)}`;

        let body = "";
        for (let i = 0; i < cuts.length; i++) {
            const c = cuts[i];
            const f = T + c.d;
            const rt = Math.min(notchRadius, c.d / 2);
            const first = i === 0;
            const end = i === last;
            const rtL = first ? Math.min(rt, Math.max(0, c.l - inset)) : rt;
            const rtR = end ? Math.min(rt, Math.max(0, W - inset - c.r)) : rt;

            if (mergedL && first) {
                const xs = Math.max(0, c.l);
                const t = Math.sqrt(xs / R);
                const ys = R * (2 * t - t * t);
                const rb = Math.min(notchRadiusBottom, (c.r - xs) / 2, Math.max(0, f - ys));
                const rj = Math.min(notchRadius, Math.max(0, f - rb - ys));
                const chord = Math.hypot(xs, ys);
                const s = chord > 0 ? Math.min(0.5, rj / chord) : 0;

                if (rj > 0.5 && s > 0) {
                    const u = 1 - s;
                    body += ` Q ${pt(0, u * t * R)} ${pt(u * u * xs, 2 * u * s * t * R + u * u * ys)}`;
                    body += ` Q ${pt(xs, ys)} ${pt(xs, ys + rj)}`;
                } else {
                    body += ` Q ${pt(0, t * R)} ${pt(xs, ys)}`;
                }
                body += ` L ${pt(xs, f - rb)} Q ${pt(xs, f)} ${pt(xs + rb, f)}`;
            } else {
                const rbL = Math.min(notchRadiusBottom, (c.r - c.l) / 2, Math.max(0, c.d - rtL));
                body += ` L ${pt(c.l - rtL, T)} Q ${pt(c.l, T)} ${pt(c.l, T + rtL)}`;
                body += ` L ${pt(c.l, f - rbL)} Q ${pt(c.l, f)} ${pt(c.l + rbL, f)}`;
            }

            if (mergedR && end) {
                const xe = Math.min(W, c.r);
                const t = Math.sqrt((W - xe) / R);
                const ye = R * (2 * t - t * t);
                const rb = Math.min(notchRadiusBottom, (xe - Math.max(0, c.l)) / 2, Math.max(0, f - ye));
                const rj = Math.min(notchRadius, Math.max(0, f - rb - ye));
                const chord = Math.hypot(W - xe, ye);
                const s = chord > 0 ? Math.min(0.5, rj / chord) : 0;

                body += ` L ${pt(xe - rb, f)} Q ${pt(xe, f)} ${pt(xe, f - rb)}`;

                if (rj > 0.5 && s > 0) {
                    const k = (1 - s) * (1 - s);
                    const bx = k * xe + (1 - k) * W;
                    const by = k * ye + 2 * s * (1 - s) * t * R;
                    body += ` L ${pt(xe, ye + rj)} Q ${pt(xe, ye)} ${pt(bx, by)}`;
                    body += ` Q ${pt(W, (1 - s) * t * R)} ${pt(W, 0)}`;
                } else {
                    body += ` L ${pt(xe, ye)} Q ${pt(W, t * R)} ${pt(W, 0)}`;
                }
            } else {
                const rbR = Math.min(notchRadiusBottom, (c.r - c.l) / 2, Math.max(0, c.d - rtR));
                body += ` L ${pt(c.r - rbR, f)} Q ${pt(c.r, f)} ${pt(c.r, f - rbR)}`;
                body += ` L ${pt(c.r, T + rtR)} Q ${pt(c.r, T)} ${pt(c.r + rtR, T)}`;
            }
        }

        let tail;
        if (floating)
            tail = ` L ${pt(W - r, 0)} Q ${pt(W, 0)} ${pt(W, r)} L ${pt(W, H - r)} Q ${pt(W, H)} ${pt(W - r, H)} L ${pt(r, H)} Q ${pt(0, H)} ${pt(0, H - r)} Z`;
        else if (mergedR)
            tail = ` L ${pt(W, H)} Z`;
        else
            tail = ` L ${pt(W - R, R)} Q ${pt(W, R)} ${pt(W, 0)} L ${pt(W, H)} Z`;

        return head + body + tail;
    }

    onHoveredItemChanged: {
        if (!hoveredItem) {
            closeTimer.restart();
            return;
        }
        const keep = notchOpen;
        const oldL = l2;
        const oldR = l3;
        target = hoveredItem;
        lagAnimated = false;
        lagL = keep ? oldL - spanL : 0;
        lagR = keep ? oldR - spanR : 0;
        lagAnimated = true;
        lagL = 0;
        lagR = 0;
        closeTimer.stop();
        notchOpen = true;
    }

    Behavior on notchProgress {
        SpringAnimation {
            spring: 4
            damping: 0.25
            epsilon: 0.25
        }
    }

    Behavior on appOffset {
        enabled: root.notchOpen && root.target === appSlot
        SpringAnimation {
            spring: 3
            damping: 0.4
            epsilon: 0.25
        }
    }

    Behavior on lagL {
        enabled: root.lagAnimated
        SpringAnimation {
            spring: 3
            damping: 0.4
            epsilon: 0.25
        }
    }

    Behavior on lagR {
        enabled: root.lagAnimated
        SpringAnimation {
            spring: 3
            damping: 0.4
            epsilon: 0.25
        }
    }

    HoverHandler {
        id: barHover
    }

    Timer {
        id: closeTimer
        interval: (barHover.hovered || root.popupShown) ? 260 : 100
        onTriggered: {
            if (root.pinned) {
                closeTimer.restart();
                return;
            }
            root.notchOpen = false;
        }
    }

    Item {
        id: hit
        anchors.fill: parent
        anchors.topMargin: root.edge === "bottom" ? root.topLine : 0
        anchors.bottomMargin: root.edge === "top" ? root.topLine : 0
        anchors.leftMargin: root.edge === "right" ? root.topLine : 0
        anchors.rightMargin: root.edge === "left" ? root.topLine : 0
    }

    Item {
        id: sessionSlot
        visible: BarConfig.moduleEnabled("power")
        readonly property bool hovered: sessionHover.hovered
        width: root.horizontal ? root.lenOf(sessionButton) : 40
        height: root.horizontal ? 40 : root.lenOf(sessionButton)
        x: root.px(root.mSessionClosed, sessionSlot)
        y: root.py(root.mSessionClosed, sessionSlot)

        HoverHandler {
            id: sessionHover
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            pathHints: ShapePath.PathSolid | ShapePath.PathNonIntersecting
            fillColor: root.colour
            strokeWidth: -1
            strokeColor: "transparent"

            PathSvg {
                path: root.outlinePath
            }
        }
    }

    Item {
        id: startSlot
        visible: BarConfig.moduleEnabled("launcher")
        readonly property bool hovered: startHover.hovered
        width: 40
        height: 40
        x: root.px(root.mStartSlot, startSlot)
        y: root.py(root.mStartSlot, startSlot)

        HoverHandler {
            id: startHover
        }
    }

    Item {
        id: mediaSlot
        visible: BarConfig.moduleEnabled("media")
        readonly property bool hovered: mediaHover.hovered
        width: root.horizontal ? mediaButton.width : 40
        height: root.horizontal ? 40 : mediaButton.height
        x: root.px(root.mMediaSlot, mediaSlot)
        y: root.py(root.mMediaSlot, mediaSlot)

        HoverHandler {
            id: mediaHover
        }
    }

    Item {
        id: dateSlot
        visible: BarConfig.moduleEnabled("date")
        readonly property bool hovered: dateHover.hovered
        width: root.horizontal ? datetime.width : 40
        height: root.horizontal ? 40 : datetime.height
        x: root.px(root.mDateSlot, dateSlot)
        y: root.py(root.mDateSlot, dateSlot)

        HoverHandler {
            id: dateHover
        }
    }

    Item {
        id: appSlot
        width: 40
        height: 40
        x: root.px(root.mApps + root.appOffset, appSlot)
        y: root.py(root.mApps + root.appOffset, appSlot)
    }

    SessionButton {
        id: sessionButton
        visible: BarConfig.moduleEnabled("power")
        vertical: !root.horizontal
        open: root.notchOpen && root.target === sessionButton
        x: root.px(root.mSessionSlot, sessionButton)
        y: root.py(root.mSessionSlot, sessionButton)
    }

    Workspace {
        id: workspace
        visible: BarConfig.moduleEnabled("workspaces")
        screen: root.screen
        vertical: !root.horizontal
        x: root.px(root.mWorkspace, workspace)
        y: root.py(root.mWorkspace, workspace)
    }

    ActiveWindow {
        id: activeWindow
        visible: BarConfig.moduleEnabled("title")
        vertical: !root.horizontal
        availableLength: Math.max(0, root.mApps - root.edgePad - root.itemGap
            - BarConfig.leftOrder.filter(key => key !== "title" && BarConfig.moduleEnabled(key))
                .reduce((sum, key) => sum + root.moduleLength(key) + root.itemGap, 0))
        x: root.px(root.modulePosition("title", "left"), activeWindow)
        y: root.py(root.modulePosition("title", "left"), activeWindow)
    }

    StartButton {
        id: startMenu
        visible: BarConfig.moduleEnabled("launcher")
        open: root.notchOpen && root.target === startMenu
        x: root.px(root.mStart, startMenu)
        y: root.py(root.mStart, startMenu)
    }

    MediaButton {
        id: mediaButton
        visible: BarConfig.moduleEnabled("media")
        vertical: !root.horizontal
        open: root.notchOpen && root.target === mediaButton
        x: root.px(root.mMedia, mediaButton)
        y: root.py(root.mMedia, mediaButton)
    }

    OpenedApp {
        id: openedApp
        vertical: !root.horizontal
        notched: root.notchOpen && root.target === appSlot
        pushAmount: root.notchPadding
        x: root.px(root.mApps, openedApp)
        y: root.py(root.mApps, openedApp)
    }

    Battery {
        id: battery
        visible: BarConfig.moduleEnabled("battery")
        vertical: !root.horizontal
        x: root.px(root.mBattery, battery)
        y: root.py(root.mBattery, battery)
    }

    DateTime {
        id: datetime
        visible: BarConfig.moduleEnabled("date")
        vertical: !root.horizontal
        x: root.px(root.mDate, datetime)
        y: root.py(root.mDate, datetime)
    }

    WifiButton {
        id: wifiButton
        visible: BarConfig.moduleEnabled("wifi")
        open: root.notchOpen && root.target === wifiButton
        x: root.px(root.mWifi, wifiButton)
        y: root.py(root.mWifi, wifiButton)
    }

    Controls {
        id: controls
        visible: BarConfig.moduleEnabled("controls")
        vertical: !root.horizontal
        x: root.px(root.mControls, controls)
        y: root.py(root.mControls, controls)
    }

    RecordingIndicator {
        id: recordingIndicator
        vertical: !root.horizontal
        x: root.px(root.mRec, recordingIndicator)
        y: root.py(root.mRec, recordingIndicator)
    }

    GitHubButton {
        id: github
        visible: BarConfig.moduleEnabled("github")
        vertical: !root.horizontal
        open: root.notchOpen && root.target === github
        x: root.px(root.mGitHub, github)
        y: root.py(root.mGitHub, github)
    }

    NightModeButton {
        id: nightMode
        visible: BarConfig.moduleEnabled("nightlight")
        x: root.px(root.modulePosition("nightlight", "right"), nightMode)
        y: root.py(root.modulePosition("nightlight", "right"), nightMode)
    }

    PowerProfileButton {
        id: powerProfile
        visible: BarConfig.moduleEnabled("performance")
        x: root.px(root.modulePosition("performance", "right"), powerProfile)
        y: root.py(root.modulePosition("performance", "right"), powerProfile)
    }

    PopupHost {
        id: host
        shown: root.popupShown
        content: root.activeContent
        gap: root.popupGap
        edge: root.edge
        centerM: (root.l2 + root.l3) / 2
        attach: root.attach

        Loader {
            id: nightLoader
            readonly property Item owner: nightMode
            anchors.centerIn: parent
            active: root.notchOpen && root.target === owner
            sourceComponent: NightModePopup { active: true }
        }

        Loader {
            id: performanceLoader
            readonly property Item owner: powerProfile
            anchors.centerIn: parent
            active: root.notchOpen && root.target === owner
            sourceComponent: PowerProfilePopup { active: true }
        }

        Loader {
            id: controlsLoader
            readonly property Item owner: controls
            anchors.centerIn: parent
            active: root.notchOpen && root.target === owner
            sourceComponent: ControlsPopup {
                pill: controls
                active: true
            }
        }

        Loader {
            id: githubLoader
            readonly property Item owner: github
            anchors.centerIn: parent
            active: root.notchOpen && root.target === owner
            sourceComponent: GitHubPopup {
                active: true
            }
        }

        Loader {
            id: wifiLoader
            readonly property Item owner: wifiButton
            anchors.centerIn: parent
            active: root.notchOpen && root.target === owner
            sourceComponent: WifiPopup {
                active: true
            }
        }

        Loader {
            id: calendarLoader
            readonly property Item owner: datetime
            anchors.centerIn: parent
            active: root.notchOpen && root.target === owner
            sourceComponent: CalendarPopup {
                active: true
            }
        }

        Loader {
            id: previewLoader
            readonly property Item owner: appSlot
            anchors.centerIn: parent
            active: root.notchOpen && root.target === owner
            sourceComponent: WindowPreviewPopup {
                active: true
                group: openedApp.hoverGroup
                maxWidth: root.horizontal ? root.width - 2 * host.edgeMargin - host.pad * 2 : (root.parent ? root.parent.width : 1920) - root.thickness - (root.floating ? BarConfig.dockMargin : 0) - root.popupGap - 2 * host.edgeMargin - host.pad * 2
            }
        }

        Loader {
            id: mediaLoader
            readonly property Item owner: mediaButton
            anchors.centerIn: parent
            active: root.notchOpen && root.target === owner
            sourceComponent: MediaPopup {
                active: true
            }
        }

        Loader {
            id: startLoader
            readonly property Item owner: startMenu
            x: host.pad
            y: root.edge === "top" ? host.pad : parent.height - height - host.pad
            active: root.notchOpen && root.target === owner
            sourceComponent: StartMenuPopup {
                active: true
            }
        }
    }
}
