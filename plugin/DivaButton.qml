import QtQuick
import qs.Commons
import "core/Icons.js" as Icons

// A pill button in Diva's colours.
Rectangle {
  id: root
  property var diva
  property string text: ""
  // Name of an icon in core/Icons.js, drawn before the text.
  property string glyph: ""
  property bool primary: false
  // Icon above the text, for the square buttons of the control centre.
  property bool stacked: false
  signal clicked()

  implicitWidth: face.implicitWidth + Style.space(text ? 28 : 20)
  implicitHeight: Style.space(34)
  radius: height / 2
  color: primary ? diva.deepRose : area.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : diva.tileColor
  border.width: 1
  border.color: primary ? "transparent" : diva.hairline
  opacity: enabled ? 1 : 0.45
  scale: area.pressed ? 0.96 : 1
  Behavior on color { ColorAnimation { duration: root.diva.ms(120) } }
  Behavior on scale { NumberAnimation { duration: root.diva.ms(90) } }

  Grid {
    id: face
    anchors.centerIn: parent
    columns: root.stacked ? 1 : 2
    spacing: root.stacked ? Style.space(3) : Style.space(7)
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    Text {
      visible: root.glyph !== ""
      text: root.glyph ? Icons.glyph(root.glyph) : ""
      color: root.primary ? root.diva.ink : root.diva.rose
      font.family: root.diva.iconFamily
      font.pixelSize: Style.space(root.stacked ? 19 : 16)
    }
    Text {
      id: label
      visible: root.text !== ""
      textFormat: Text.PlainText
      text: root.text
      color: root.diva.ink
      font.family: root.diva.fontFamily
      font.pixelSize: Style.space(root.stacked ? 11 : 13)
      font.weight: Font.Medium
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
