import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import "core/Desktop.js" as Desktop

// Live window copies interpolate from desktop geometry into the overview.
// The compositor's layout never changes just to display the overview.
Item {
  id: root
  property var windows: []
  property var workspaces: []
  property int workspace: 1
  property real progress: 1
  property string appFilter: ""
  property string status: ""
  property real monitorX: 0
  property real monitorY: 0
  property bool capturing: true
  property int selected: 0
  readonly property var shown: windows.filter(function(w) { return root.appFilter ? w.appId === root.appFilter : w.workspace === root.workspace })
  readonly property var layout: Desktop.grid(shown.length, Math.max(1,width - 100), Math.max(1,height - 260))
  signal activated(string address)
  signal dismissed()
  signal workspaceActivated(int number)
  signal windowMoved(string address, int number)
  signal workspaceAdded()
  focus: true
  onShownChanged: selected = Math.min(selected, Math.max(0, shown.length - 1))
  Keys.onEscapePressed: dismissed()
  Keys.onLeftPressed: selected = Math.max(0, selected - 1)
  Keys.onRightPressed: selected = Math.min(shown.length - 1, selected + 1)
  Keys.onUpPressed: selected = Math.max(0, selected - layout.columns)
  Keys.onDownPressed: selected = Math.min(shown.length - 1, selected + layout.columns)
  Keys.onReturnPressed: if (shown[selected]) activated(shown[selected].address)

  Rectangle { anchors.fill: parent; color: "#20121e"; opacity: root.progress * 0.94 }
  MouseArea { anchors.fill: parent; onClicked: root.dismissed() }
  Text {
    x: 48; y: 22; text: root.appFilter ? "Fenêtres de cette application" : "Mes espaces"
    textFormat: Text.PlainText; color: "#f6e9ef"; font.family: Style.font.family; font.pixelSize: 22; opacity: root.progress
  }
  Text { anchors.right: parent.right; anchors.rightMargin: 48; y: 26; text: "Échap pour revenir"; color: "#cfb2c2"; opacity: root.progress; font.pixelSize: 13 }
  Flickable {
    id: strip
    x: 48; y: 64; width: parent.width - 96; height: 120
    contentWidth: spaces.width; clip: true; opacity: root.progress
    flickableDirection: Flickable.HorizontalFlick
    Row {
      id: spaces
      spacing: 14
      Repeater {
        model: root.workspaces
        Rectangle {
          id: space
          required property var modelData
          readonly property var localWindows: root.windows.filter(function(w) { return w.workspace === space.modelData.id })
          width: 156; height: 104; radius: 15
          color: drop.containsDrag ? "#74445e" : root.workspace === modelData.id && !root.appFilter ? "#58364e" : "#362230"
          border.width: 2; border.color: drop.containsDrag || root.workspace === modelData.id && !root.appFilter ? "#eaa3c0" : "#65445a"
          Row {
            anchors.centerIn: parent; spacing: 4
            Repeater {
              model: space.localWindows.slice(0,3)
              Rectangle {
                id: miniature
                required property var modelData
                width: 42; height: 32; radius: 5; color: "#714b64"
                Image { anchors.fill: parent; anchors.margins: 4; source: Quickshell.iconPath(miniature.modelData.icon, true); visible: !miniCopy.hasContent }
                ScreencopyView { id: miniCopy; anchors.fill: parent; captureSource: root.capturing && root.progress > 0.1 ? miniature.modelData.handle : null; live: true }
              }
            }
          }
          Text { x: 10; y: 8; text: space.modelData.name; textFormat: Text.PlainText; color: "#f6e9ef"; font.pixelSize: 12; width: parent.width - 20; elide: Text.ElideRight }
          Text { anchors.bottom: parent.bottom; anchors.bottomMargin: 7; anchors.horizontalCenter: parent.horizontalCenter; text: space.localWindows.length + " fenêtre" + (space.localWindows.length > 1 ? "s" : ""); color: "#cfb2c2"; font.pixelSize: 10 }
          MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: { root.workspace = space.modelData.id; root.appFilter = "" } onClicked: root.workspaceActivated(space.modelData.id) }
          DropArea {
            id: drop; anchors.fill: parent; keys: ["diva-window"]
            onDropped: function(event) { if (event.source && event.source.address) { root.windowMoved(event.source.address, space.modelData.id); event.acceptProposedAction() } }
          }
        }
      }
      Rectangle {
        width: 66; height: 104; radius: 15; color: "#362230"; border.color: "#65445a"
        Text { anchors.centerIn: parent; text: "+"; color: "#eaa3c0"; font.pixelSize: 30 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.workspaceAdded() }
      }
    }
  }
  Text {
    x: 50; y: 193; text: root.status || "Clique une fenêtre pour la retrouver · Glisse-la vers un espace pour la déplacer"
    width: parent.width - 100; wrapMode: Text.WordWrap; color: "#cfb2c2"; font.pixelSize: 12; opacity: root.progress
  }
  Text { visible: root.shown.length === 0; anchors.centerIn: parent; text: "Cet espace est libre."; color: "#cfb2c2"; font.pixelSize: 22; opacity: root.progress }
  Repeater {
    model: root.shown
    Item {
      id: card
      required property int index
      required property var modelData
      readonly property real targetWidth: Math.min(root.layout.width, Math.max(1,root.layout.height - 36) * modelData.size[0] / Math.max(1,modelData.size[1]))
      readonly property real targetHeight: targetWidth * modelData.size[1] / Math.max(1,modelData.size[0]) + 36
      readonly property real targetX: 50 + (index % root.layout.columns) * (root.layout.width + 22) + (root.layout.width - targetWidth) / 2
      readonly property real targetY: 236 + Math.floor(index / root.layout.columns) * (root.layout.height + 22) + (root.layout.height - targetHeight) / 2
      readonly property real startX: modelData.monitor === root.monitorName ? modelData.at[0] - root.monitorX : root.width / 2
      readonly property real startY: modelData.monitor === root.monitorName ? modelData.at[1] - root.monitorY : root.height / 2
      x: startX + (targetX - startX) * root.progress
      y: startY + (targetY - startY) * root.progress
      width: modelData.size[0] + (targetWidth - modelData.size[0]) * root.progress
      height: modelData.size[1] + (targetHeight - modelData.size[1]) * root.progress
      z: pointer.drag.active ? 20 : modelData.active ? 2 : 1
      Rectangle {
        id: surface
        property string address: card.modelData.address
        width: parent.width; height: parent.height; radius: 18; color: "#362230"
        border.width: 2; border.color: root.selected === card.index || pointer.containsMouse ? "#eaa3c0" : "#65445a"
        Drag.active: pointer.drag.active
        Drag.keys: ["diva-window"]
        Drag.hotSpot.x: width / 2; Drag.hotSpot.y: height / 2
        ClippingRectangle {
          x: 3 * root.progress; y: 3 * root.progress
          width: parent.width - 6 * root.progress; height: Math.max(1, parent.height - 36 * root.progress)
          radius: 15 * root.progress; color: "#241520"
          Image { anchors.centerIn: parent; width: Math.min(parent.width * 0.4,64); height: width; source: Quickshell.iconPath(card.modelData.icon, true); visible: !copy.hasContent }
          ScreencopyView { id: copy; anchors.fill: parent; captureSource: root.capturing ? card.modelData.handle : null; live: true }
        }
        Text {
          x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
          width: parent.width - 24; text: card.modelData.title; textFormat: Text.PlainText
          elide: Text.ElideRight; font.pixelSize: 12; color: "#f6e9ef"; opacity: root.progress
        }
        MouseArea {
          id: pointer
          anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          drag.target: root.progress > 0.98 ? surface : null
          drag.threshold: 12
          onClicked: root.activated(card.modelData.address)
          onReleased: { surface.Drag.drop(); surface.x = 0; surface.y = 0 }
          onCanceled: { surface.x = 0; surface.y = 0 }
        }
      }
    }
  }
  property string monitorName: ""
}
