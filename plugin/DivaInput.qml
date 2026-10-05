import QtQuick
import qs.Commons

// A labelled text field. `committed` fires on Enter or when focus leaves
// with a changed value.
Item {
  id: root
  property var diva
  property string label: ""
  property string value: ""
  property string placeholder: ""
  property bool password: false
  readonly property alias text: field.text
  signal committed(string text)

  function clear() { field.text = "" }
  function focusField() { field.forceActiveFocus() }

  implicitHeight: Style.space(40)
  onValueChanged: if (!field.activeFocus) field.text = value

  Text {
    id: caption
    textFormat: Text.PlainText
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: root.label ? Style.space(150) : 0
    text: root.label
    color: root.diva.ink
    font.family: root.diva.fontFamily
    font.pixelSize: Style.space(14)
    elide: Text.ElideRight
  }

  Rectangle {
    anchors.left: caption.right
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    height: Style.space(36)
    radius: height / 2
    color: root.diva.field
    border.width: Style.space(1.5)
    border.color: field.activeFocus ? root.diva.rose : root.diva.tileSelected
    Behavior on border.color { ColorAnimation { duration: root.diva.ms(150) } }

    TextInput {
      id: field
      anchors.fill: parent
      anchors.leftMargin: Style.space(14)
      anchors.rightMargin: Style.space(14)
      verticalAlignment: TextInput.AlignVCenter
      clip: true
      text: root.value
      echoMode: root.password ? TextInput.Password : TextInput.Normal
      color: root.diva.ink
      selectionColor: root.diva.deepRose
      selectedTextColor: root.diva.ink
      font.family: root.diva.fontFamily
      font.pixelSize: Style.space(14)
      onAccepted: root.committed(text)
      onActiveFocusChanged: if (!activeFocus && !root.password && text !== root.value) root.committed(text)

      Text {
        textFormat: Text.PlainText
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        visible: !field.text
        text: root.placeholder
        color: root.diva.soft
        opacity: 0.6
        elide: Text.ElideRight
        font: field.font
      }
    }
  }
}
