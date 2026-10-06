import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import "core/Desktop.js" as Desktop

Item {
  id: root
  property int barSize: 40
  property bool vertical: false
  // Which screen edge the bar is on; the window previews open away from it.
  property string edge: "bottom"
  readonly property bool lively: config.animations !== false
  readonly property string helper: decodeURIComponent(String(Qt.resolvedUrl("bin/diva-window")).replace(/^file:\/\//,""))
  property var config: ({})
  property real pointer: -1000
  readonly property int slot: Math.round(barSize * 1.25)
  implicitWidth: vertical ? barSize : Math.min(Style.space(420), (desktopModel.dock.length + 1) * slot)
  implicitHeight: vertical ? (desktopModel.dock.length + 1) * slot : barSize
  DesktopModel { id: desktopModel; pins: root.config.dockPins || null }
  FileView {
    id: settingsFile
    path: Quickshell.env("HOME") + "/.config/diva/config.json"
    watchChanges: true; printErrors: false
    onFileChanged: reload()
    onLoaded: { try { root.config = JSON.parse(text()) } catch(e) {} }
  }
  function pin(app) {
    // Preserve every unrelated setting, including edits by the menu.
    var next = JSON.parse(settingsFile.text() || "{}")
    var pins = Array.isArray(next.dockPins) ? next.dockPins.slice() : desktopModel.dock.filter(function(g) { return g.pinned }).map(function(g) { return g.id })
    var i = pins.indexOf(app.id)
    if (i >= 0) pins.splice(i, 1); else pins.push(app.id)
    next.dockPins = pins
    root.config = next; settingsFile.setText(JSON.stringify(next, null, 2) + "\n"); desktopModel.update()
  }
  // A click goes to the window of that app used last; if she is already
  // there, to the one before it, so two windows swap with repeated clicks.
  // Picking a particular window is done from the previews shown on hover.
  function activate(app) {
    peek.close()
    if (app.windows.length > 0) {
      var order = Desktop.byRecency(app.windows)
      var target = order[0].active && order.length > 1 ? order[1] : order[0]
      Quickshell.execDetached([root.helper, "focus", target.address, "--now"])
    } else {
      var entry = (DesktopEntries.applications.values || []).find(function(e) { return e.id === app.id })
      if (entry) entry.execute()
    }
  }
  HoverHandler {
    onPointChanged: root.pointer = root.vertical ? point.position.y + ribbon.contentY : point.position.x + ribbon.contentX
    onHoveredChanged: if (!hovered) root.pointer = -1000
  }
  Flickable {
    id: ribbon
    anchors.fill: parent
    contentWidth: root.vertical ? root.barSize : (desktopModel.dock.length + 1) * root.slot
    contentHeight: root.vertical ? (desktopModel.dock.length + 1) * root.slot : root.barSize
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: root.vertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick
    WheelHandler {
      onWheel: function(event) {
        var delta = event.angleDelta.y || event.angleDelta.x
        if (root.vertical) ribbon.contentY = Math.max(0,Math.min(ribbon.contentHeight-ribbon.height,ribbon.contentY-delta/3))
        else ribbon.contentX = Math.max(0,Math.min(ribbon.contentWidth-ribbon.width,ribbon.contentX-delta/3))
        event.accepted = true
      }
    }
  Repeater {
    model: desktopModel.dock
    Item {
      id: icon
      required property int index
      required property var modelData
      x: root.vertical ? 0 : index * root.slot
      y: root.vertical ? index * root.slot : 0
      width: root.vertical ? root.barSize : root.slot
      height: root.vertical ? root.slot : root.barSize
      Accessible.name: modelData.name
      Accessible.description: "Clic pour ouvrir; clic droit pour épingler ou retirer du dock"
      readonly property real proximity: Desktop.magnification(root.pointer - (index + 0.5) * root.slot, root.slot * 2)
      Image {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.vertical ? 0 : -2
        width: root.barSize * (0.54 + icon.proximity * 0.36); height: width
        source: Quickshell.iconPath(icon.modelData.icon || "application-x-executable", true)
        sourceSize.width: root.barSize * 2; sourceSize.height: root.barSize * 2
        Behavior on width { NumberAnimation { duration: root.config.animations === false ? 0 : 110; easing.type: Easing.OutCubic } }
      }
      Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 1; anchors.horizontalCenter: parent.horizontalCenter; width: modelData.active ? 12 : 4; height: 3; radius: 2; color: "#eaa3c0"; visible: modelData.windows.length > 0 }
      MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onEntered: peek.aim(icon.modelData.id, icon)
        onExited: peek.leave()
        onClicked: function(mouse) { if (mouse.button === Qt.RightButton) root.pin(icon.modelData); else root.activate(icon.modelData) }
      }

    }
  }
  Item {
    x: root.vertical ? 0 : desktopModel.dock.length * root.slot
    y: root.vertical ? desktopModel.dock.length * root.slot : 0
    width: root.vertical ? root.barSize : root.slot; height: root.vertical ? root.slot : root.barSize
    Text { anchors.centerIn: parent; text: "▦"; color: "#eaa3c0"; font.pixelSize: root.barSize * 0.64 }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["omarchy-shell", "diva.desktop", "show"]) }
  }
  }

  // Hovering an open app shows its windows, live, to pick one: the taskbar
  // previews of Windows 11. It waits a moment before opening, and stays while
  // the pointer is on the icon or on the previews.
  PopupWindow {
    id: peek
    property string appId: ""
    property Item target: null
    property bool open: false
    readonly property var app: desktopModel.dock.find(function(g) { return g.id === peek.appId }) || null
    readonly property var list: app ? app.windows : []
    readonly property int gap: Style.space(8)
    function aim(id, item) {
      away.stop()
      var app = desktopModel.dock.find(function(g) { return g.id === id })
      if (!app || !app.windows.length) { if (open) leave(); return }
      pending.id = id; pending.item = item
      if (open) pending.triggered(); else pending.restart()
    }
    function leave() { pending.stop(); away.restart() }
    function close() { pending.stop(); away.stop(); open = false }
    onListChanged: if (open && !list.length) close()
    Timer {
      id: pending
      property string id: ""
      property Item item: null
      interval: 380
      onTriggered: { peek.appId = id; peek.target = item; peek.open = true; peek.anchor.updateAnchor() }
    }
    Timer { id: away; interval: 280; onTriggered: peek.open = false }

    visible: open || card.opacity > 0.01
    color: "transparent"
    implicitWidth: card.width
    implicitHeight: card.height
    anchor {
      window: root.QsWindow.window
      adjustment: PopupAdjustment.Slide
      edges: Edges.Top | Edges.Left
      gravity: Edges.Bottom | Edges.Right
      rect.width: 1
      rect.height: 1
      onAnchoring: {
        var window = root.QsWindow.window
        if (!peek.target || !window) return
        var x = peek.target.width / 2 - peek.implicitWidth / 2, y = -peek.implicitHeight - peek.gap
        if (root.edge === "top") y = peek.target.height + peek.gap
        else if (root.edge === "left") { x = peek.target.width + peek.gap; y = peek.target.height / 2 - peek.implicitHeight / 2 }
        else if (root.edge === "right") { x = -peek.implicitWidth - peek.gap; y = peek.target.height / 2 - peek.implicitHeight / 2 }
        var point = window.contentItem.mapFromItem(peek.target, x, y)
        peek.anchor.rect.x = Math.round(point.x)
        peek.anchor.rect.y = Math.round(point.y)
      }
    }
    onImplicitWidthChanged: if (visible) anchor.updateAnchor()

    Rectangle {
      id: card
      width: previews.width + Style.space(20)
      height: previews.height + Style.space(20)
      radius: Style.space(18)
      color: Qt.rgba(0.17, 0.11, 0.16, 0.96)
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.16)
      opacity: peek.open ? 1 : 0
      scale: peek.open ? 1 : 0.94
      transformOrigin: root.edge === "top" ? Item.Top : root.edge === "left" ? Item.Left : root.edge === "right" ? Item.Right : Item.Bottom
      Behavior on opacity { NumberAnimation { duration: root.lively ? 150 : 0; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: root.lively ? 150 : 0; easing.type: Easing.OutCubic } }
      HoverHandler { onHoveredChanged: if (hovered) { away.stop(); pending.stop() } else if (peek.open) peek.leave() }
      Row {
        id: previews
        anchors.centerIn: parent
        spacing: Style.space(10)
        Repeater {
          model: peek.list
          Rectangle {
            id: preview
            required property var modelData
            readonly property real shot: Style.space(118)
            width: Math.max(Style.space(130), Math.min(Style.space(230), shot * modelData.size[0] / Math.max(1, modelData.size[1])))
            height: shot + Style.space(30)
            radius: Style.space(12)
            color: over.containsMouse ? Qt.rgba(0.92, 0.64, 0.75, 0.2) : modelData.active ? Qt.rgba(1, 1, 1, 0.09) : "transparent"
            border.width: 1
            border.color: over.containsMouse ? "#eaa3c0" : modelData.active ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
            Behavior on color { ColorAnimation { duration: root.lively ? 120 : 0 } }
            Image {
              id: mark
              x: Style.space(8); y: Style.space(7)
              width: Style.space(16); height: width; sourceSize.width: 32; sourceSize.height: 32
              source: Quickshell.iconPath(preview.modelData.icon || "application-x-executable", true)
            }
            Text {
              anchors.left: mark.right; anchors.leftMargin: Style.space(6)
              anchors.right: shut.left; anchors.rightMargin: Style.space(4)
              anchors.verticalCenter: mark.verticalCenter
              text: preview.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight
              color: "#f6e9ef"; font.family: Style.font.family; font.pixelSize: Style.space(11)
            }
            ClippingRectangle {
              x: Style.space(6); y: Style.space(28)
              width: parent.width - Style.space(12); height: preview.shot - Style.space(4)
              radius: Style.space(8)
              color: "#241520"
              Image {
                anchors.centerIn: parent; width: Style.space(36); height: width; sourceSize.width: 72; sourceSize.height: 72
                source: mark.source; visible: !copy.hasContent
              }
              ScreencopyView {
                id: copy
                anchors.centerIn: parent
                // Fit inside, in the window's own proportions.
                readonly property real fit: Math.min(parent.width / Math.max(1, preview.modelData.size[0]), parent.height / Math.max(1, preview.modelData.size[1]))
                width: preview.modelData.size[0] * fit; height: preview.modelData.size[1] * fit
                captureSource: peek.visible ? preview.modelData.handle : null
                live: true
              }
            }
            MouseArea {
              id: over
              anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: { Quickshell.execDetached([root.helper, "focus", preview.modelData.address, "--now"]); peek.close() }
            }
            Rectangle {
              id: shut
              anchors.right: parent.right; anchors.rightMargin: Style.space(6); y: Style.space(5)
              width: Style.space(20); height: width; radius: width / 2
              color: shutArea.containsMouse ? "#e0607f" : "transparent"
              opacity: over.containsMouse || shutArea.containsMouse ? 1 : 0
              DivaGlyph { anchors.centerIn: parent; name: "close"; family: Style.font.family; size: Style.space(11); color: "#f6e9ef" }
              MouseArea {
                id: shutArea
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached([root.helper, "close-address", preview.modelData.address, "--now"])
              }
            }
          }
        }
      }
    }
  }
}
