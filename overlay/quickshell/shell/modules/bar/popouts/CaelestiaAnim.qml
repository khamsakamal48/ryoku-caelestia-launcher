import QtQuick
import shell.services

// Caelestia's Anim (caelestia-dots/shell components/Anim.qml) on Ryoku's
// reduce-motion/speed knobs. Spatial moves overshoot a touch (expressive
// default spatial, 500 ms); effects (opacity) settle in 200 ms.
NumberAnimation {
    property bool effects: false

    duration: Motion.dur(effects ? 200 : 500)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: effects ? [0.34, 0.8, 0.34, 1, 1, 1] : [0.38, 1.21, 0.22, 1, 1, 1]
}
