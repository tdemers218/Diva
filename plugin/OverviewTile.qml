import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import "core/Desktop.js" as Desktop

// One window (or one tab group) on the overview map. It is a live copy at
// the window's own proportions; it can be dragged onto another tile or a
// workspace, resized from its edge, and carries a few buttons on hover.
// All coordinates are the overview's, so the copy can fly in from where the
// real window is on screen.
Item {
  id: card
  required property string address
  required property int index
  property var overview: null

  readonly property var blank: ({ x: 0, y: 0, width: 160, height: 100, members: [], floating: false, stacked: false, share: 0,
                                  window: { at: [0, 0], size: [160, 100], title: "", icon: "", monitor: "", workspace: 0, handle: null } })
  readonly property bool known: overview.byAddress[address] !== undefined
  readonly property var tile: known ? overview.byAddress[address] : blank
  readonly property var win: tile.window
  readonly property bool grouped: tile.members.length > 1
  readonly property bool editable: overview.plan.editable && overview.settled
  readonly property bool lively: overview.animate
  // Only the tile on top under the pointer reacts, not the ones beneath it.
  readonly property bool hovered: hover.hovered && overview.settled && overview.dragging === "" && overview.hoverTop === address
  readonly property bool selected: overview.selectedAddress === address
  // The real window is on screen right now, so the copy starts from it.
  readonly property bool onScreen: win.monitor === overview.monitorName && win.workspace === overview.homeWorkspace

  property bool dragging: false
  property bool resizing: false
  property bool closing: false
  property real dragX: 0
  property real dragY: 0
  property real tilt: 0
  property real grow: 0
  property real growY: 0
  property real pressX: width / 2
  property real pressY: height / 2
  property real appear: 1
  property real share: tile.share

  readonly property real inset: overview.plan.editable ? 4 : 0
  // Place and size move together, on one curve and for one duration, so a
  // tile never crosses its neighbour on the way.
  property real tx: tile.x + inset
  property real ty: tile.y + inset
  property real tw: Math.max(12, tile.width - inset * 2)
  property real th: Math.max(12, tile.height - inset * 2)
  Behavior on tx { enabled: card.lively && overview.settled && !overview.quiet; NumberAnimation { duration: overview.pace; easing.type: Easing.OutCubic } }
  Behavior on ty { enabled: card.lively && overview.settled && !overview.quiet; NumberAnimation { duration: overview.pace; easing.type: Easing.OutCubic } }
  Behavior on tw { enabled: card.lively && overview.settled && !overview.quiet; NumberAnimation { duration: overview.pace; easing.type: Easing.OutCubic } }
  Behavior on th { enabled: card.lively && overview.settled && !overview.quiet; NumberAnimation { duration: overview.pace; easing.type: Easing.OutCubic } }

  readonly property real p: overview.progress
  // While an edge is pulled, the columns after it make room at once.
  readonly property real pushed: !tile.floating && overview.shiftFrom >= 0 && tile.column > overview.shiftFrom ? overview.shiftBy : 0
  readonly property real restX: overview.originX + tx + pushed - overview.scroll + overview.slide
  readonly property real restY: overview.originY + ty
  readonly property real fromX: onScreen ? win.at[0] - overview.monitorX : restX
  readonly property real fromY: onScreen ? win.at[1] - overview.monitorY : restY
  readonly property real fromW: onScreen ? win.size[0] : tw
  readonly property real fromH: onScreen ? win.size[1] : th
  x: fromX + (restX - fromX) * p + dragX
  y: fromY + (restY - fromY) * p + dragY
  width: Math.max(12, fromW + (tw + grow - fromW) * p)
  height: Math.max(12, fromH + (th + growY - fromH) * p)
  z: dragging ? 60 : resizing ? 50 : (tile.floating ? 30 : 10) + (hovered ? 2 : 0) + (selected ? 1 : 0)
  visible: known
  opacity: (onScreen ? 1 : p) * appear * (closing ? 0 : 1)
  Behavior on opacity { enabled: card.lively && card.closing; NumberAnimation { duration: 180 } }

  // Picked up, it shrinks under the pointer and leans the way it travels.
  transform: [
    Scale {
      origin.x: card.pressX; origin.y: card.pressY
      xScale: card.lift; yScale: card.lift
    },
    Rotation { origin.x: card.pressX; origin.y: card.pressY; angle: card.tilt }
  ]
  property real lift: (closing ? 0.7 : dragging ? Math.min(0.78, 300 / Math.max(1, width)) : hovered && !resizing ? 1.015 : 1) * (0.95 + 0.05 * appear)
  Behavior on lift { enabled: card.lively; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
  Behavior on tilt { enabled: card.lively; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  Behavior on dragX { enabled: card.lively && !card.dragging; NumberAnimation { duration: overview.pace; easing.type: Easing.OutCubic } }
  Behavior on dragY { enabled: card.lively && !card.dragging; NumberAnimation { duration: overview.pace; easing.type: Easing.OutCubic } }

  // Arriving on a workspace that was just chosen: tiles fade up together
  // with the slide, a beat apart, without overshooting into each other.
  SequentialAnimation {
    id: arrive
    PauseAnimation { duration: Math.min(card.index, 6) * 22 }
    NumberAnimation { target: card; property: "appear"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
  }
  Component.onCompleted: if (lively && overview.active && overview.settled) { appear = 0; arrive.start() }
  // A pulled edge keeps its preview until Hyprland has applied the new size.
  onTileChanged: if (overview.quiet) { grow = 0; growY = 0 }
  Timer { id: giveUp; interval: 1400; onTriggered: { card.grow = 0; card.growY = 0; card.closing = false } }
  Timer { id: straighten; interval: 90; onTriggered: card.tilt = 0 }
  HoverHandler {
    id: hover
    onPointChanged: if (hovered) { var at = card.mapToItem(overview, point.position.x, point.position.y); overview.hoverAt(at.x, at.y) }
    onHoveredChanged: if (!hovered && overview.hoverTop === card.address) { overview.hoverTop = ""; overview.hint = "" }
  }
  onHoveredChanged: if (hovered) overview.selectedAddress = address

  // A soft shadow from three faint layers; no blur pass on a laptop GPU.
  Repeater {
    model: 3
    Rectangle {
      required property int index
      x: -index * 3; y: 4 + index * 2
      width: card.width + index * 6; height: card.height + index * 4
      radius: surface.radius + index * 3
      color: "#000000"
      opacity: (card.dragging ? 0.16 : 0.09) * card.p
    }
  }

  Rectangle {
    id: surface
    anchors.fill: parent
    radius: 16 * card.p
    color: "#362230"
    border.width: 2
    border.color: card.dragging || card.resizing ? "#ffd0e2" : card.hovered || card.selected ? "#eaa3c0" : tile.floating ? "#8a6a80" : "#65445a"
    Behavior on border.color { ColorAnimation { duration: card.lively ? 140 : 0 } }

    ClippingRectangle {
      x: 2 * card.p; y: 2 * card.p
      width: parent.width - 4 * card.p; height: parent.height - 4 * card.p
      radius: 14 * card.p
      color: "#241520"
      Image {
        anchors.centerIn: parent
        width: Math.max(16, Math.min(parent.width * 0.4, parent.height * 0.5, 64)); height: width
        sourceSize.width: 64; sourceSize.height: 64
        source: Quickshell.iconPath(card.win.icon || "application-x-executable", true)
        visible: !copy.hasContent
      }
      ScreencopyView {
        id: copy
        anchors.fill: parent
        captureSource: overview.capturing && card.known ? card.win.handle : null
        live: true
      }
      // Name and icon on a soft shade at the foot of the window.
      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: Math.min(40, parent.height * 0.5)
        opacity: card.p * (card.height > 70 ? 1 : 0)
        gradient: Gradient {
          GradientStop { position: 0; color: Qt.rgba(0.1, 0.05, 0.09, 0) }
          GradientStop { position: 1; color: Qt.rgba(0.1, 0.05, 0.09, card.hovered || card.selected ? 0.92 : 0.7) }
        }
        Image {
          id: badge
          x: 9; anchors.bottom: parent.bottom; anchors.bottomMargin: 7
          width: 18; height: 18; sourceSize.width: 36; sourceSize.height: 36
          source: Quickshell.iconPath(card.win.icon || "application-x-executable", true)
        }
        Text {
          anchors.left: badge.right; anchors.leftMargin: 7
          anchors.verticalCenter: badge.verticalCenter
          width: parent.width - 46
          text: card.win.title
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: "#f6e9ef"
          font.family: Style.font.family
          font.pixelSize: 12
          visible: parent.width > 110
        }
      }
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: card.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    property real startX: 0
    property real startY: 0
    onPressed: function(mouse) {
      var at = mapToItem(overview, mouse.x, mouse.y)
      startX = at.x; startY = at.y
      card.pressX = mouse.x; card.pressY = mouse.y
    }
    onPositionChanged: function(mouse) {
      if (!pressed || !overview.settled) return
      var at = mapToItem(overview, mouse.x, mouse.y)
      var dx = at.x - startX, dy = at.y - startY
      if (!card.dragging) {
        if (Math.abs(dx) < 10 && Math.abs(dy) < 10) return
        card.dragging = true
        overview.dragBegan(card.address)
      }
      card.tilt = Math.max(-7, Math.min(7, (dx - card.dragX) * 0.7))
      straighten.restart()
      card.dragX = dx; card.dragY = dy
      overview.dragMoved(card.address, at.x, at.y, (mouse.modifiers & Qt.ShiftModifier) !== 0)
    }
    onReleased: {
      if (!card.dragging) { overview.activated(card.address); return }
      card.dragging = false; card.tilt = 0
      overview.dragEnded(card.address)
      card.dragX = 0; card.dragY = 0
    }
    onCanceled: {
      if (card.dragging) { card.dragging = false; overview.dragCancelled() }
      card.tilt = 0; card.dragX = 0; card.dragY = 0
    }
  }

  // Tabs of a group: one icon each, the one on show marked.
  Row {
    x: 8; y: 8; spacing: 4
    visible: card.grouped && card.p > 0.98 && !card.dragging
    Repeater {
      model: card.grouped ? card.tile.members : []
      Rectangle {
        id: tab
        required property var modelData
        readonly property bool current: modelData.address === card.address
        width: 28; height: 28; radius: 10
        color: tabArea.containsMouse ? "#eaa3c0" : current ? "#8a5673" : Qt.rgba(0.13, 0.07, 0.12, 0.88)
        border.width: 1; border.color: Qt.rgba(1, 1, 1, current ? 0.4 : 0.16)
        scale: tabArea.containsMouse ? 1.12 : 1
        Behavior on scale { enabled: card.lively; SpringAnimation { spring: 5; damping: 0.36 } }
        Image {
          anchors.centerIn: parent; width: 18; height: 18; sourceSize.width: 36; sourceSize.height: 36
          source: Quickshell.iconPath(tab.modelData.icon || "application-x-executable", true)
        }
        MouseArea {
          id: tabArea
          anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onEntered: overview.hint = "Onglet : " + tab.modelData.title
          onExited: overview.hint = ""
          onClicked: overview.activated(tab.modelData.address)
        }
      }
    }
  }

  // Buttons, only on the tile under the pointer.
  Row {
    id: tools
    anchors.right: parent.right; anchors.rightMargin: 8
    y: 8; spacing: 4
    layoutDirection: Qt.RightToLeft
    visible: opacity > 0.01
    opacity: card.hovered && !card.dragging && !card.resizing && overview.settled ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: card.lively ? 130 : 0 } }
    readonly property bool roomy: card.width > 330
    OverviewChip {
      icon: "close"; danger: true; lively: card.lively; tip: "Fermer cette fenêtre"
      onHinted: function(text) { overview.hint = text }
      onTapped: { card.closing = true; giveUp.restart(); overview.closed(card.address) }
    }
    OverviewChip {
      visible: card.editable
      icon: "window-restore"; on: card.tile.floating; lively: card.lively
      tip: card.tile.floating ? "La ranger avec les autres" : "La laisser flotter par-dessus"
      onHinted: function(text) { overview.hint = text }
      onTapped: overview.floated(card.address)
    }
    OverviewChip {
      visible: card.editable && card.grouped
      icon: "layers"; lively: card.lively; tip: "Sortir cette fenêtre des onglets"
      onHinted: function(text) { overview.hint = text }
      onTapped: overview.ungrouped(card.address)
    }
    OverviewChip {
      visible: card.editable && card.tile.stacked
      icon: "window-maximize"; lively: card.lively; tip: "Lui donner sa propre colonne"
      onHinted: function(text) { overview.hint = text }
      onTapped: overview.unstacked(card.address)
    }
    Repeater {
      model: card.editable && !card.tile.floating && tools.roomy ? [[100, "", "Tout l'écran"], [67, "⅔", "Deux tiers de l'écran"], [50, "½", "La moitié de l'écran"], [33, "⅓", "Un tiers de l'écran"]] : []
      OverviewChip {
        required property var modelData
        label: modelData[1]; icon: modelData[1] ? "" : "expand"; tip: modelData[2]; lively: card.lively
        on: Math.abs(card.tile.share * 100 - modelData[0]) < 5
        onHinted: function(text) { overview.hint = text }
        onTapped: overview.widthChosen(card.address, modelData[0])
      }
    }
  }

  // Resize: the right edge of a tiled window sets its column's width, in
  // tidy fractions when close to one; the corner of a floating one is free.
  Item {
    id: grip
    readonly property bool corner: card.tile.floating
    visible: card.editable && (card.hovered || card.resizing) && !card.dragging
    x: card.width - (corner ? 22 : 9)
    y: corner ? card.height - 22 : 18
    width: corner ? 26 : 18
    height: corner ? 26 : Math.max(10, card.height - 36)
    Rectangle {
      anchors.centerIn: parent
      width: grip.corner ? 10 : 5
      height: grip.corner ? 10 : Math.min(46, parent.height)
      radius: 5
      color: gripArea.containsMouse || card.resizing ? "#ffd0e2" : "#eaa3c0"
      opacity: gripArea.containsMouse || card.resizing ? 1 : 0.7
      scale: gripArea.containsMouse || card.resizing ? 1.25 : 1
      Behavior on scale { enabled: card.lively; SpringAnimation { spring: 5; damping: 0.36 } }
    }
    MouseArea {
      id: gripArea
      anchors.fill: parent
      hoverEnabled: true
      preventStealing: true
      cursorShape: grip.corner ? Qt.SizeFDiagCursor : Qt.SizeHorCursor
      property real startX: 0
      property real startY: 0
      property real moveX: 0
      property real moveY: 0
      onEntered: overview.hint = grip.corner ? "Tire le coin pour changer sa taille" : "Tire le bord pour changer sa largeur"
      onExited: if (!pressed) overview.hint = ""
      onPressed: function(mouse) {
        var at = mapToItem(overview, mouse.x, mouse.y)
        startX = at.x; startY = at.y; moveX = 0; moveY = 0
        card.resizing = true; overview.resizing = true
      }
      onPositionChanged: function(mouse) {
        if (!pressed) return
        var at = mapToItem(overview, mouse.x, mouse.y)
        moveX = at.x - startX; moveY = at.y - startY
        if (grip.corner) {
          card.grow = Math.max(60 - card.tw, moveX); card.growY = Math.max(40 - card.th, moveY)
          overview.hint = Math.round((card.tw + card.grow) / overview.plan.scale) + " × " + Math.round((card.th + card.growY) / overview.plan.scale)
        } else {
          card.share = Desktop.snapWidth((card.tile.width + moveX) / Math.max(1, overview.plan.viewport.width))
          card.grow = card.share * overview.plan.viewport.width - card.tile.width
          overview.shiftFrom = card.tile.column; overview.shiftBy = card.grow
          overview.hint = Desktop.widthLabel(card.share)
        }
      }
      onReleased: {
        card.resizing = false; overview.resizing = false; overview.hint = ""
        if (Math.abs(moveX) < 3 && Math.abs(moveY) < 3) { card.grow = 0; card.growY = 0; overview.release(); return }
        overview.hold(); giveUp.restart()
        if (grip.corner) overview.resizedBy(card.address, Math.round(card.grow / overview.plan.scale), Math.round(card.growY / overview.plan.scale))
        else overview.widthChosen(card.address, Math.round(card.share * 100))
      }
      onCanceled: { card.resizing = false; overview.resizing = false; card.grow = 0; card.growY = 0; overview.hint = ""; overview.release() }
    }
  }

  // The width it will take, written on the window while its edge is pulled.
  Rectangle {
    anchors.centerIn: parent
    visible: card.resizing && !grip.corner
    width: sizeText.implicitWidth + 28; height: 34; radius: 17
    color: Qt.rgba(0.13, 0.07, 0.12, 0.9)
    border.width: 1; border.color: "#eaa3c0"
    Text {
      id: sizeText
      anchors.centerIn: parent
      text: Desktop.widthLabel(card.share)
      textFormat: Text.PlainText
      color: "#f6e9ef"
      font.family: Style.font.family
      font.pixelSize: 15
      font.weight: Font.DemiBold
    }
  }
}
