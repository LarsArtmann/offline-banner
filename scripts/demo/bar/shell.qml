pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Minimal desktop bar for the demo capture: sits at the top edge with an
// exclusive zone, so the banner's push-down animation visibly displaces it.
// Not part of the module — scene dressing for scripts/capture-demo.sh.
ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 32
        color: "#181825"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "nixos  ·  offline-banner demo"
            color: "#cdd6f4"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "12:47"
            color: "#cdd6f4"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }
}
