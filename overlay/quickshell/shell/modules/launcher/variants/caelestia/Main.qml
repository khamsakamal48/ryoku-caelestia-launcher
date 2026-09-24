import QtQuick
import Quickshell
import shell.services
import "../../shared/providers" as SharedProviders

// Caelestia launcher variant. The body is not a window of its own: it is the
// frame surface "caelestia-launcher" (modules/bar/FrameSurface.qml ->
// popouts/CaelestiaLauncher.qml) that grows out of the bottom border. This
// root only opens/closes that surface and keeps Ryoku's providers registered on
// the shared Dispatcher so the body can query them.
Scope {
    id: root

    readonly property string surfaceId: "caelestia-launcher"
    property bool open: false
    property string openMon: ""
    readonly property bool shown: open

    function show(mon) {
        if (root.open)
            return;
        root.open = true;
        root.openMon = mon || "";
        ShellState.requestSurface(root.surfaceId, root.openMon, null);
    }

    function hide() {
        if (!root.open)
            return;
        root.open = false;
        ShellState.closeSurface(root.surfaceId, root.openMon);
    }

    function toggle(mon) {
        if (root.open)
            root.hide();
        else
            root.show(mon);
    }

    function stateDump() {
        return { open: root.open, monitor: root.openMon };
    }

    SharedProviders.Providers {}
}
