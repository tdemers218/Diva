import QtQuick
import qs.Commons
import "core/Icons.js" as Icons

// A thick control-centre slider: the whole bar is the handle.
Rectangle {
  id: root
  property var diva
  property string glyph: ""
  property string label: ""
  // 0..100; -1 when the value is unknown (no such control on this machine).
  property int value: 0
  property bool dimmed: false
  signal moved(int value)

  // While dragging, show the finger's value, not the last one read back.
  property int dragValue: -1
  readonly property int shown: dragValue >= 0 ? dragValue : Math.max(0, value)

  implicitHeight: Style.space(54)
  radius: Style.space(20)
  color: diva.tileColor
  border.width: 1
  border.color: diva.hairline
  opacity: value < 0 ? 0.4 : 1
  clip: true

  Rectangle {
    width: Math.max(parent.height, parent.width * root.shown / 100)
    height: parent.height
    radius: parent.radius
    color: root.dimmed ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0.89, 0.6, 0.72, 0.62)
    Behavior on width { NumberAnimation { duration: area.pressed ? 0 : root.diva.ms(160); easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: root.diva.ms(150) } }
  }

  Text {
    anchors.left: parent.left
    anchors.leftMargin: Style.space(17)
    anchors.verticalCenter: parent.verticalCenter
    text: Icons.glyph(root.glyph)
    color: root.diva.ink
    font.family: root.diva.iconFamily
    font.pixelSize: Style.space(21)
  }
  Text {
    textFormat: Text.PlainText
    anchors.left: parent.left
    anchors.leftMargin: Style.space(50)
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: root.diva.ink
    font.family: root.diva.fontFamily
    font.pixelSize: Style.space(14)
    font.weight: Font.Medium
  }
  Text {
    textFormat: Text.PlainText
    anchors.right: parent.right
    anchors.rightMargin: Style.space(16)
    anchors.verticalCenter: parent.verticalCenter
    text: root.value < 0 ? "" : root.shown + " %"
    color: root.diva.ink
    opacity: 0.85
    font.family: root.diva.fontFamily
    font.pixelSize: Style.space(13)
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.value >= 0
    cursorShape: Qt.PointingHandCursor
    function at(x) { return Math.max(0, Math.min(100, Math.round(x / width * 100))) }
    onPressed: function(mouse) { root.dragValue = at(mouse.x); root.moved(root.dragValue) }
    onPositionChanged: function(mouse) { if (pressed) { root.dragValue = at(mouse.x); root.moved(root.dragValue) } }
    onReleased: release.restart()
    onWheel: function(wheel) { root.moved(Math.max(0, Math.min(100, root.shown + (wheel.angleDelta.y > 0 ? 5 : -5)))) }
  }
  // Hold the dragged value until the machine has caught up.
  Timer { id: release; interval: 700; onTriggered: root.dragValue = -1 }
}
