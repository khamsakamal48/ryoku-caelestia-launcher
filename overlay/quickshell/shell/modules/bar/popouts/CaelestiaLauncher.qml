pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services
import "../../launcher/shared/Singletons" as L

// Caelestia's launcher (caelestia-dots/shell modules/launcher/Content.qml) on
// Ryoku's providers. The search bar sits on the bottom lip and results grow
// upward, so the frame surface "caelestia-launcher" (FrameSurface.qml) reads as
// the bottom border swelling open. Every Ryoku provider answers through the
// shared Dispatcher: apps, "/" actions, "=" calc, "?" web, clipboard, files...
Item {
    id: root

    property real s: 1
    property bool open: false
    property bool menuOpen: false
    property string monitorName: ""
    signal requestClose()

    readonly property real pad: 16 * s

    implicitWidth: 600 * s + pad * 2
    implicitHeight: search.height + listBox.height + pad * 2

    // --- results ------------------------------------------------------------
    // Provider queries may start async work, so evaluate outside bindings and
    // repaint on Dispatcher revisions (same rule as variants/main/Launcher.qml).
    property var results: []
    property bool queued: false
    readonly property var routed: L.Dispatcher.route(search.text)

    function evaluate() {
        root.queued = false;
        if (!root.open) {
            root.results = [];
            return;
        }
        // An empty query lists every app, as Caelestia does.
        root.results = search.text.length === 0
            ? L.Dispatcher.resultsFor("apps", "", "", 0)
            : L.Dispatcher.results(search.text, L.Metrics.maxResults);
    }
    function schedule() {
        if (root.queued)
            return;
        root.queued = true;
        Qt.callLater(root.evaluate);
    }
    function activate(i) {
        const row = root.results[i];
        const action = row && row.actions && row.actions.length > 0 ? row.actions[0] : null;
        if (!action || action.enabled === false || !action.execute)
            return;
        action.execute();
        if (action.closeOnExecute !== false)
            root.requestClose();
    }

    Connections {
        target: L.Dispatcher
        function onRevisionChanged() { root.schedule(); }
    }

    // Any close (Escape, click-out, a launch, another surface replacing us)
    // clears this monitor's launcherOpen, so the next Super+Space opens first
    // time instead of first toggling a stale flag off.
    onMenuOpenChanged: {
        if (root.menuOpen) {
            search.forceActiveFocus();
            return;
        }
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name !== root.monitorName)
                continue;
            const st = ShellState.forScreen(screens[i]);
            if (st)
                st.launcherOpen = false;
        }
    }
    Component.onCompleted: {
        root.schedule();
        search.forceActiveFocus();
    }

    // --- list ---------------------------------------------------------------
    Item {
        id: listBox

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: search.top
        anchors.margins: root.pad
        height: list.count > 0 ? list.implicitHeight : empty.implicitHeight
        clip: true

        Behavior on height {
            enabled: root.menuOpen
            CaelestiaAnim {}
        }

        CaelestiaResultList {
            id: list
            anchors.fill: parent
            s: root.s
            rows: root.results
            mode: root.routed.provider + "|" + root.routed.prefix
            onActivated: i => root.activate(i)
        }

        Row {
            id: empty
            anchors.centerIn: parent
            spacing: 12 * root.s
            padding: 16 * root.s
            opacity: list.count === 0 ? 1 : 0
            scale: list.count === 0 ? 1 : 0.5

            Behavior on opacity { CaelestiaAnim { effects: true } }
            Behavior on scale { CaelestiaAnim {} }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "manage_search"
                color: Theme.onSurfaceVariant
                font.family: "Material Symbols Rounded"
                font.pixelSize: 32 * root.s
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: L.Dispatcher.busy ? "Searching..." : "No results"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontPrimary
                    font.pixelSize: 16 * root.s
                    font.weight: Font.Medium
                }
                Text {
                    text: "Try searching for something else"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontPrimary
                    font.pixelSize: 13 * root.s
                }
            }
        }
    }

    // --- search bar (Caelestia SearchBar: a full pill on the bottom lip) ----
    Rectangle {
        id: search

        property alias text: input.text
        function forceActiveFocus() { input.forceActiveFocus(); }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.pad
        height: 48 * root.s
        radius: height / 2
        color: Theme.surfaceContainer

        Text {
            id: glass
            anchors.left: parent.left
            anchors.leftMargin: 16 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            color: Theme.onSurfaceVariant
            font.family: "Material Symbols Rounded"
            font.pixelSize: 22 * root.s
        }

        TextInput {
            id: input

            anchors.left: glass.right
            anchors.right: parent.right
            anchors.leftMargin: 12 * root.s
            anchors.rightMargin: 16 * root.s
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.onSurface
            selectionColor: Theme.primary
            selectedTextColor: Theme.onPrimary
            font.family: Theme.fontPrimary
            font.pixelSize: 15 * root.s
            clip: true
            focus: true

            onTextChanged: root.schedule()
            onAccepted: root.activate(list.currentIndex)

            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onEscapePressed: root.requestClose()
            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))
                        || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                    list.decrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                    list.incrementCurrentIndex();
                    event.accepted = true;
                }
            }

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: input.text.length === 0
                text: "Type \"/\" for commands"
                color: Theme.outline
                font: input.font
            }
        }
    }
}
