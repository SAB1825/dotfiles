pragma Singleton

import QtQuick
import px.services.niri
import Ryu.Shell

QtObject {
    id: root

    property bool open: false
    property string screenName: ""

    function focusedName() {
        return NiriService.focusedOutput || Screens.list[0]?.name || "";
    }

    function show() {
        screenName = focusedName();
        open = true;
    }

    function hide() {
        open = false;
    }

    function toggle() {
        open ? hide() : show();
    }
}
