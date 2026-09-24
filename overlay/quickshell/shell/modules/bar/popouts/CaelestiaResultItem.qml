import QtQuick
import shell.services

// One launcher row, after Caelestia's items/AppItem.qml: icon, name, and a
// muted one-line subtitle. Driven by any Ryoku provider row, not only apps.
Item {
    id: root

    required property var modelData
    required property int index
    property real s: 1
    signal activated(int index)

    // Image when the provider hands a path/URL; otherwise its initial on a chip.
    readonly property string icon: String(modelData && modelData.icon || "")
    readonly property bool iconIsPath: icon.indexOf("/") >= 0 || icon.indexOf(":") >= 0

    implicitHeight: 57 * s
    width: ListView.view ? ListView.view.width : implicitWidth

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (root.ListView.view) root.ListView.view.currentIndex = root.index
        onClicked: root.activated(root.index)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 12 * root.s
        anchors.rightMargin: 12 * root.s
        anchors.topMargin: 8 * root.s
        anchors.bottomMargin: 8 * root.s

        Item {
            id: iconBox
            width: parent.height * 0.8
            height: width
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                visible: root.iconIsPath
                source: root.iconIsPath ? root.icon : ""
                asynchronous: true
                sourceSize.width: Math.round(width * 2)
                sourceSize.height: Math.round(height * 2)
                fillMode: Image.PreserveAspectFit
            }

            Rectangle {
                anchors.fill: parent
                visible: !root.iconIsPath
                radius: width / 2
                color: Theme.secondaryContainer

                Text {
                    anchors.centerIn: parent
                    text: String(root.modelData && root.modelData.title || "?").charAt(0).toUpperCase()
                    color: Theme.onSecondaryContainer
                    font.family: Theme.fontPrimary
                    font.pixelSize: parent.height * 0.5
                    font.weight: Font.Medium
                }
            }
        }

        Column {
            anchors.left: iconBox.right
            anchors.leftMargin: 12 * root.s
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: String(root.modelData && root.modelData.title || "")
                color: Theme.onSurface
                font.family: Theme.fontPrimary
                font.pixelSize: 15 * root.s
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: text.length > 0
                text: String(root.modelData && root.modelData.subtitle || "")
                color: Theme.outline
                font.family: Theme.fontPrimary
                font.pixelSize: 12 * root.s
                elide: Text.ElideRight
            }
        }
    }
}
