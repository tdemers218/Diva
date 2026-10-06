import QtQuick
import qs.Commons

// A small round button on a window in the overview: an icon or a short
// label. `tip` is what Diva says about it while the pointer is on it.
Rectangle {
  id: root
  property string icon: ""
  property string label: ""
  property string tip: ""
  property bool on: false
  property bool danger: false
  property bool lively: true
  signal tapped()
  signal hinted(string text)

  width: label ? Math.max(height, text.implicitWidth + 16) : height
  height: 26
  radius: height / 2
  color: area.containsMouse ? (danger ? "#e0607f" : "#eaa3c0") : on ? "#8a5673" : Qt.rgba(0.13, 0.07, 0.12, 0.88)
  border.width: 1
  border.color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.4 : 0.16)
  scale: area.pressed ? 0.88 : area.containsMouse ? 1.12 : 1
  Behavior on scale { enabled: root.lively; SpringAnimation { spring: 5; damping: 0.36 } }
  Behavior on color { ColorAnimation { duration: root.lively ? 120 : 0 } }

  DivaGlyph {
    visible: root.icon !== ""
    anchors.centerIn: parent
    name: root.icon
    family: Style.font.family
    size: 14
    color: area.containsMouse ? "#2b1c29" : "#f6e9ef"
  }
  Text {
    id: text
    visible: root.label !== ""
    anchors.centerIn: parent
    text: root.label
    textFormat: Text.PlainText
    color: area.containsMouse ? "#2b1c29" : "#f6e9ef"
    font.family: Style.font.family
    font.pixelSize: 13
    font.weight: Font.DemiBold
  }
  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: root.hinted(root.tip)
    onExited: root.hinted("")
    onClicked: root.tapped()
  }
}
