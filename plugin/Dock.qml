import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "core/Desktop.js" as Desktop

Item {
  id: root
  property int barSize: 40
  property bool vertical: false
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
  function activate(app) {
    if (app.windows.length === 1) Quickshell.execDetached([decodeURIComponent(String(Qt.resolvedUrl("bin/diva-window")).replace(/^file:\/\//,"")), "focus", app.windows[0].address])
    else if (app.windows.length > 1) Quickshell.execDetached(["omarchy-shell", "diva.desktop", "showApp", app.id])
    else {
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
}
