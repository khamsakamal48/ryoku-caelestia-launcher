pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons

// Visual-only Ryoku Settings preview: a card rising out of the bottom frame
// border, rows above a pill search bar, the first row highlighted.
Item {
    id: root

    property var settings: ({})
    signal editRequested(string key, var value)

    implicitWidth: 720
    implicitHeight: 250

    readonly property var applications: ["Firefox", "Kitty", "Files"]

    Rectangle {
        anchors.fill: parent
        color: Tokens.paper
    }

    // the bottom frame border the launcher grows out of
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Tokens.s2
        color: Tokens.paperLift
    }

    Rectangle {
        id: card
        width: 400
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: col.implicitHeight + Tokens.s3 * 2
        radius: 20
        color: Tokens.paperLift
        border.width: Tokens.border
        border.color: Tokens.lineStrong

        // square off the bottom so the card reads as welded to the border
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.radius
            color: parent.color
        }

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.s3
            spacing: Tokens.s1

            Repeater {
                model: root.applications
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: col.width
                    height: 34
                    radius: 12
                    color: index === 0 ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                    Rectangle {
                        id: dot
                        width: 22; height: 22; radius: 11
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.s2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Tokens.lineStrong
                    }
                    Text {
                        anchors.left: dot.right
                        anchors.leftMargin: Tokens.s2
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fRow
                    }
                }
            }

            Rectangle {
                width: col.width
                height: 34
                radius: 17
                color: Tokens.paper

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.s3
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("Type \"/\" for commands")
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fRow
                }
            }
        }
    }
}
