import QtQuick
import qs.Commons

// A labelled on/off switch.
Item {
  id: root
  property var diva
  property string label: ""
  property string caption: ""
  property bool checked: false
  signal toggled(bool value)

  implicitHeight: Math.max(Style.space(38), texts.implicitHeight + Style.space(8))

  Column {
    id: texts
    anchors.left: parent.left
    anchors.right: track.left
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(1)
    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: root.label
      color: root.diva.ink
      font.family: root.diva.fontFamily
      font.pixelSize: Style.space(14)
      elide: Text.ElideRight
    }
    Text {
      textFormat: Text.PlainText
      visible: root.caption !== ""
      width: parent.width
      text: root.caption
      color: root.diva.soft
      font.family: root.diva.fontFamily
      font.pixelSize: Style.space(12)
      wrapMode: Text.WordWrap
    }
  }

  Rectangle {
    id: track
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(46)
    height: Style.space(26)
    radius: height / 2
    color: root.checked ? root.diva.deepRose : Qt.rgba(1, 1, 1, 0.12)
    Behavior on color { ColorAnimation { duration: root.diva.ms(150) } }

    Rectangle {
      width: parent.height - Style.space(6)
      height: width
      radius: width / 2
      y: Style.space(3)
      x: root.checked ? parent.width - width - Style.space(3) : Style.space(3)
      color: root.diva.ink
      Behavior on x { NumberAnimation { duration: root.diva.ms(150); easing.type: Easing.OutCubic } }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled(!root.checked)
  }
}
