pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services

// Caelestia's launcher list (modules/launcher/AppList.qml): a sliding
// highlight, fade/slide transitions as rows come and go, and a fade-scale swap
// when the query changes mode (apps -> "/" actions -> "=" calc ...). Rows are
// keyed by Ryoku's resultKey so a re-query moves surviving rows instead of
// rebuilding them.
ListView {
    id: root

    property real s: 1
    property var rows: []
    property string mode: ""
    readonly property int maxShown: 7
    signal activated(int index)

    property var shownRows: []
    onRowsChanged: if (!modeSwap.running) shownRows = rows
    onModeChanged: modeSwap.restart()

    model: ScriptModel {
        values: root.shownRows
        objectProp: "resultKey"
        onValuesChanged: root.currentIndex = 0
    }

    spacing: 8 * s
    clip: true
    implicitHeight: count > 0 ? (57 * s + spacing) * Math.min(maxShown, count) - spacing : 0
    boundsBehavior: Flickable.StopAtBounds

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: Rectangle {
        radius: 16 * root.s
        color: Theme.onSurface
        opacity: 0.08
        y: root.currentItem ? root.currentItem.y : 0
        width: root.width
        height: root.currentItem ? root.currentItem.implicitHeight : 0

        Behavior on y {
            CaelestiaAnim {}
        }
    }

    delegate: CaelestiaResultItem {
        s: root.s
        onActivated: i => root.activated(i)
    }

    SequentialAnimation {
        id: modeSwap
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: Motion.dur(200); easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 1, 1, 1, 1] }
            NumberAnimation { target: root; property: "scale"; to: 0.9; duration: Motion.dur(200); easing.type: Easing.BezierSpline; easing.bezierCurve: [0.3, 0, 1, 1, 1, 1] }
        }
        ScriptAction { script: root.shownRows = root.rows }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: Motion.dur(200); easing.type: Easing.BezierSpline; easing.bezierCurve: [0, 0, 0, 1, 1, 1] }
            NumberAnimation { target: root; property: "scale"; to: 1; duration: Motion.dur(200); easing.type: Easing.BezierSpline; easing.bezierCurve: [0, 0, 0, 1, 1, 1] }
        }
    }

    add: Transition {
        CaelestiaAnim { effects: true; property: "opacity"; from: 0; to: 1 }
    }
    remove: Transition {
        CaelestiaAnim { effects: true; property: "opacity"; from: 1; to: 0 }
    }
    move: Transition {
        CaelestiaAnim { property: "y" }
        CaelestiaAnim { effects: true; property: "opacity"; to: 1 }
    }
    addDisplaced: Transition {
        NumberAnimation { property: "y"; duration: Motion.dur(200); easing.type: Easing.BezierSpline; easing.bezierCurve: [0.2, 0, 0, 1, 1, 1] }
        CaelestiaAnim { effects: true; property: "opacity"; to: 1 }
    }
    displaced: Transition {
        CaelestiaAnim { property: "y" }
        CaelestiaAnim { effects: true; property: "opacity"; to: 1 }
    }
}
