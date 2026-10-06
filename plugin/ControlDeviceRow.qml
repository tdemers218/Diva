import QtQuick
import qs.Commons

// A quiet row inside a settings panel; the panel supplies the visual boundary.
Rectangle {
  id: root
  property var diva
  property string title: ""
  property string subtitle: ""
  property string glyph: "wifi"
  property string forgetLabel: "Oublier cet appareil"
  property string action: "Connecter"
  property bool selected: false
  property bool busy: false
  property bool canForget: false
  property bool expanded: false
  property bool confirming: false
  signal activated()
  signal forgotten()
  width: parent.width
  implicitHeight: Math.max(Style.space(62), details.height + Style.space(22)) + (expanded ? forgetActions.height + Style.space(12) : 0)
  radius: Style.space(10)
  color: selected ? Qt.rgba(0.92,0.64,0.75,0.09) : hover.containsMouse ? Qt.rgba(1,1,1,0.035) : "transparent"
  Behavior on color { ColorAnimation { duration: root.diva.ms(120) } }
  MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
  DivaGlyph { x: Style.space(10); y: Style.space(19); family: root.diva.iconFamily; name: root.glyph; size: Style.space(20); color: root.selected ? root.diva.rose : root.diva.soft }
  Column {
    id: details
    x: Style.space(42); y: Style.space(12)
    width: Math.max(0, buttons.x - x - Style.space(10)); spacing: Style.space(4)
    Text { width: parent.width; text: root.title; textFormat: Text.PlainText; color: root.diva.ink; font.family: root.diva.fontFamily; font.pixelSize: Style.space(13); font.weight: Font.Medium; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
    Text { width: parent.width; text: root.busy ? "En cours…" : root.subtitle; textFormat: Text.PlainText; color: root.selected ? root.diva.rose : root.diva.soft; font.family: root.diva.fontFamily; font.pixelSize: Style.space(10); elide: Text.ElideRight }
  }
  Row {
    id: buttons
    anchors.right: parent.right; anchors.rightMargin: Style.space(8); y: Style.space(17); spacing: Style.space(4)
    Item {
      width: actionText.implicitWidth + Style.space(12); height: Style.space(28)
      opacity: root.enabled && !root.busy ? 1 : 0.5
      Text { id: actionText; anchors.centerIn: parent; text: root.busy ? "Patiente…" : root.action; color: root.diva.rose; font.family: root.diva.fontFamily; font.pixelSize: Style.space(11); font.weight: Font.Medium }
      activeFocusOnTab: true
      Keys.onReturnPressed: if (enabled && !root.busy) root.activated()
      Keys.onSpacePressed: if (enabled && !root.busy) root.activated()
      Rectangle { anchors.fill: parent; color: "transparent"; radius: Style.space(6); border.color: root.diva.rose; visible: parent.activeFocus }
      MouseArea { anchors.fill: parent; enabled: root.enabled && !root.busy; cursorShape: Qt.PointingHandCursor; onClicked: root.activated() }
    }
    DivaButton { diva: root.diva; glyph: "cog"; width: Style.space(28); height: width; visible: root.canForget; enabled: !root.busy; color: "transparent"; border.color: "transparent"; onClicked: { root.expanded = !root.expanded; root.confirming = false } }
  }
  Flow {
    id: forgetActions
    visible: root.expanded; x: Style.space(42); y: Math.max(Style.space(62), details.height + Style.space(22))
    width: parent.width - x - Style.space(8); spacing: Style.space(6)
    DivaButton { diva: root.diva; text: root.confirming ? "Confirmer l’oubli" : root.forgetLabel; enabled: !root.busy; onClicked: { if (root.confirming) { root.forgotten(); root.expanded = false } else root.confirming = true } }
    DivaButton { diva: root.diva; text: "Annuler"; visible: root.confirming; onClicked: { root.confirming = false; root.expanded = false } }
  }
}
