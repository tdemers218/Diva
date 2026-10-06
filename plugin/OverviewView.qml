import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import "core/Desktop.js" as Desktop

// The overview: every workspace as a small map along the top, and the chosen
// one drawn to scale below, each window a live copy in its real proportions
// and at its real place. Windows are rearranged here by hand: dragged next
// to, under or onto one another, onto another workspace, or resized from
// their edge. Nothing is changed in Hyprland just to display the overview;
// the copies fly in from where the real windows are.
Item {
  id: root
  property var windows: []
  property var workspaces: []
  property int workspace: 1
  // The workspace on screen behind the overview.
  property int homeWorkspace: 1
  property real progress: 1
  property bool active: true
  property bool animate: true
  property string appFilter: ""
  property string status: ""
  property bool statusOk: true
  property int statusTick: 0
  property real monitorX: 0
  property real monitorY: 0
  property string monitorName: ""
  // Screen rectangles by monitor name, in layout coordinates.
  property var views: ({})
  property bool capturing: true

  property string hint: ""
  property string dragging: ""
  property bool resizing: false
  property var dropTarget: null
  property string selectedAddress: ""
  property real scroll: 0
  // A resize in progress: columns after `shiftFrom` are pushed by `shiftBy`.
  // `quiet` holds that preview, unanimated, until the real layout arrives.
  property int shiftFrom: -1
  property real shiftBy: 0
  property bool quiet: false
  function hold() { quiet = true; unhold.restart() }
  function release() { shiftFrom = -1; shiftBy = 0; quiet = false }
  Timer { id: unhold; interval: 1400; onTriggered: root.release() }
  Timer { id: calm; interval: 40; onTriggered: root.release() }
  property real slide: 0
  property real pointerX: width / 2
  property real pointerY: height / 2

  readonly property bool settled: progress > 0.98
  // Every layout change in the overview runs for this long, on one curve.
  readonly property int pace: 260
  // True while tiles are travelling to a new layout: outlines drawn around
  // them step back until they have arrived instead of jumping ahead of them.
  property bool moving: false
  Timer { id: arrived; interval: root.pace + 40; onTriggered: root.moving = false }
  readonly property real areaX: 48
  readonly property real areaY: 214
  readonly property real areaW: Math.max(1, width - 96)
  readonly property real areaH: Math.max(1, height - areaY - 92)
  readonly property var shown: windows.filter(function(w) { return root.appFilter ? w.appId === root.appFilter : w.workspace === root.workspace })
  readonly property var plan: appFilter
    ? Desktop.gallery(shown, { width: areaW, height: areaH })
    : Desktop.map(shown, viewFor(shown), { width: areaW, height: areaH }, 0.2)
  property var byAddress: ({})
  property string lastShape: "-"
  property var frames: []
  readonly property real maxScroll: Math.max(0, plan.width - areaW)
  readonly property real originX: areaX + Math.max(0, (areaW - plan.width) / 2)
  readonly property real originY: areaY + (areaH - plan.height) / 2
  readonly property int selected: {
    for (var i = 0; i < plan.tiles.length; i++) if (plan.tiles[i].address === selectedAddress) return i
    return -1
  }

  signal activated(string address)
  signal dismissed()
  signal workspaceActivated(int number)
  signal workspaceAdded()
  signal windowMoved(string address, int number)
  signal windowToNewWorkspace(string address)
  signal arranged(string address, string target, string how)
  signal widthChosen(string address, int percent)
  signal resizedBy(string address, int dx, int dy)
  signal closed(string address)
  signal floated(string address)
  signal ungrouped(string address)
  signal unstacked(string address)
  signal pulledOut(string address)
  // The view never sets `workspace` or `appFilter` itself: an assignment here
  // would cut the binding from its owner, and the overview would then reopen
  // on whichever workspace was last looked at. It asks, and the owner sets.
  signal workspacePicked(int number)

  function viewFor(list) {
    var v = list.length ? views[list[0].monitor] : null
    return v || views[monitorName] || { x: monitorX, y: monitorY, width: Math.max(1, width), height: Math.max(1, height) }
  }
  // The tile on top at a point: floating windows lie over the tiled ones.
  property string hoverTop: ""
  function hoverAt(px, py) {
    for (var i = plan.tiles.length - 1; i >= 0; i--) {
      var t = plan.tiles[i], x = originX + t.x - scroll, y = originY + t.y
      if (px >= x && px <= x + t.width && py >= y && py <= y + t.height) { hoverTop = t.address; return }
    }
    hoverTop = ""
  }

  // Tiles are kept in a model keyed by window, so a tile that only moved or
  // changed size glides to its new place instead of being rebuilt.
  ListModel { id: tiles }
  onPlanChanged: sync()
  Component.onCompleted: sync()
  function sync() {
    var next = {}
    plan.tiles.forEach(function(t) { next[t.address] = t })
    for (var i = tiles.count - 1; i >= 0; i--) if (!next[tiles.get(i).address]) tiles.remove(i)
    // Only a change of shape counts as movement; a window title that
    // changes rebuilds the plan too and must not make anything blink.
    var shape = plan.tiles.map(function(t) { return [t.address, Math.round(t.x), Math.round(t.y), Math.round(t.width), Math.round(t.height)].join(":") }).join(" ")
    if (shape !== lastShape) {
      lastShape = shape
      if (animate && settled && active && !quiet) { moving = true; arrived.restart() }
      frames = plan.editable ? Desktop.screens(plan, "") : []
    }
    byAddress = next
    var have = {}
    for (var j = 0; j < tiles.count; j++) have[tiles.get(j).address] = true
    plan.tiles.forEach(function(t) { if (!have[t.address]) tiles.append({ address: t.address }) })
    if (!next[selectedAddress]) {
      var front = plan.tiles.find(function(t) { return t.window.active }) || plan.tiles[0]
      selectedAddress = front ? front.address : ""
    }
    scroll = Math.max(0, Math.min(maxScroll, scroll))
    if (quiet) { shiftFrom = -1; shiftBy = 0; unhold.stop(); calm.restart() }
  }
  // Start on the part of the ribbon that is on screen.
  function recentre() { scroll = Math.max(0, Math.min(maxScroll, plan.viewport.x + plan.viewport.width / 2 - areaW / 2)) }
  function reveal(address) {
    var t = byAddress[address]
    if (!t || maxScroll <= 0) return
    if (t.x - scroll < 0) scroll = Math.max(0, t.x - 20)
    else if (t.x + t.width - scroll > areaW) scroll = Math.min(maxScroll, t.x + t.width - areaW + 20)
  }
  property int lastWorkspace: workspace
  onWorkspaceChanged: {
    if (animate && settled && active) { slide = workspace > lastWorkspace ? 60 : -60; glide.restart() }
    lastWorkspace = workspace
    hint = ""
    recentre()
  }
  onActiveChanged: if (active) { hint = ""; dropTarget = null; dragging = ""; Qt.callLater(recentre) }
  NumberAnimation { id: glide; target: root; property: "slide"; to: 0; duration: root.pace; easing.type: Easing.OutCubic }
  Behavior on scroll { enabled: root.animate && root.dragging === ""; NumberAnimation { duration: root.pace; easing.type: Easing.OutCubic } }

  // Diva cheers when something worked.
  property bool cheering: false
  property bool sorry: false
  onStatusTickChanged: if (status) { cheering = statusOk; sorry = !statusOk; mood.restart(); if (statusOk) avatar.poke() }
  Timer { id: mood; interval: 1600; onTriggered: { root.cheering = false; root.sorry = false } }

  // --- Dragging a window ---------------------------------------------------

  property real dragAtX: 0
  property real dragAtY: 0
  function dragBegan(address) { dragging = address; dropTarget = null }
  // The middle of a window shares the screen with it (halves, then quarters);
  // with Shift held it makes tabs instead, Hyprland's own kind of group.
  function dragMoved(address, px, py, tabs) {
    dragAtX = px; dragAtY = py
    var source = byAddress[address]
    var found = null
    for (var i = 0; i < spaceRepeater.count && !found; i++) {
      var item = spaceRepeater.itemAt(i)
      var at = item.mapToItem(root, 0, 0)
      if (px >= at.x && px <= at.x + item.width && py >= at.y && py <= at.y + item.height && (root.appFilter || item.modelData.id !== root.workspace))
        found = { kind: "workspace", id: item.modelData.id, label: "Envoyer vers " + item.modelData.name }
    }
    if (!found) {
      var plus = addSpace.mapToItem(root, 0, 0)
      if (px >= plus.x && px <= plus.x + addSpace.width && py >= plus.y && py <= plus.y + addSpace.height)
        found = { kind: "new", label: "Lui donner un nouvel espace" }
    }
    if (!found && plan.editable && source) {
      var own = source.members.map(function(m) { return m.address })
      for (var j = plan.tiles.length - 1; j >= 0 && !found; j--) {
        var t = plan.tiles[j]
        if (own.indexOf(t.address) >= 0) continue
        var x = originX + t.x - scroll, y = originY + t.y
        if (px < x || px > x + t.width || py < y || py > y + t.height) continue
        var zone = Desktop.dropZone(px - x, py - y, t.width, t.height, t.floating)
        if (zone === "group") zone = tabs ? "tabs" : Desktop.joinKind(plan, address, t.address)
        if (!zone) continue
        var name = t.window.title.length > 30 ? t.window.title.slice(0, 29) + "…" : t.window.title
        found = { kind: zone, address: t.address, x: x, y: y, width: t.width, height: t.height,
                  label: zone === "before" ? "Placer avant « " + name + " »" : zone === "after" ? "Placer après « " + name + " »"
                    : zone === "stack" ? "Empiler sous « " + name + " »" : zone === "tabs" ? "En onglets avec « " + name + " »"
                    : zone === "pair" ? "Côte à côte avec « " + name + " », une moitié chacune  ·  Maj pour des onglets"
                    : zone === "quarter" ? "Rejoindre cet écran : un quart pour elle  ·  Maj pour des onglets"
                    : "Cet écran est plein : elle commence le suivant  ·  Maj pour des onglets" }
      }
    }
    // Dropped on nothing, away from what it shares: it leaves it.
    if (!found && plan.editable && source) {
      var leave = Desktop.leaveKind(plan, address)
      if (leave) {
        var lx = originX + leave.rect.x - scroll, ly = originY + leave.rect.y, away = 6
        if (px < lx - away || px > lx + leave.rect.width + away || py < ly - away || py > ly + leave.rect.height + away)
          found = { kind: "out", label: leave.kind === "tabs" ? "Lâche ici : elle sort des onglets"
            : leave.kind === "screen" ? "Lâche ici : elle quitte cet écran partagé et retrouve toute sa place"
            : "Lâche ici : elle retrouve sa propre colonne" }
      }
    }
    dropTarget = found
    hint = found ? found.label : ""
    nudge.direction = maxScroll > 0 && py > areaY ? (px < areaX + 50 ? -1 : px > areaX + areaW - 50 ? 1 : 0) : 0
  }
  function dragEnded(address) {
    var target = dropTarget
    dragging = ""; dropTarget = null; hint = ""; nudge.direction = 0
    if (!target) return false
    if (target.kind === "workspace") windowMoved(address, target.id)
    else if (target.kind === "new") windowToNewWorkspace(address)
    else if (target.kind === "out") pulledOut(address)
    else arranged(address, target.address, target.kind === "tabs" ? "group"
      : target.kind === "pair" || target.kind === "quarter" || target.kind === "beside" ? "pair" : target.kind)
    return true
  }
  function dragCancelled() { dragging = ""; dropTarget = null; hint = ""; nudge.direction = 0 }
  // Near the side of a long ribbon, a dragged window makes it scroll.
  Timer {
    id: nudge
    property int direction: 0
    interval: 16; repeat: true; running: direction !== 0 && root.dragging !== ""
    onTriggered: root.scroll = Math.max(0, Math.min(root.maxScroll, root.scroll + direction * 14))
  }

  // --- Keyboard --------------------------------------------------------------

  function step(by) {
    if (!plan.tiles.length) return
    var i = Math.max(0, Math.min(plan.tiles.length - 1, (selected < 0 ? 0 : selected) + by))
    selectedAddress = plan.tiles[i].address
    reveal(selectedAddress)
  }
  function neighbour(by) {
    var t = plan.tiles[selected]
    if (!t || t.floating) return null
    return plan.tiles.find(function(o) { return !o.floating && o.column === t.column + by && o.row === 0 }) || null
  }
  function cycle(by) {
    var ids = workspaces.map(function(w) { return w.id })
    var i = ids.indexOf(workspace)
    if (ids.length) workspacePicked(ids[(Math.max(0, i) + by + ids.length) % ids.length])
  }
  focus: true
  Keys.onPressed: function(event) {
    var t = plan.tiles[selected]
    var shift = event.modifiers & Qt.ShiftModifier
    var edit = plan.editable && t
    event.accepted = true
    if (event.key === Qt.Key_Shift && dragging !== "") { dragMoved(dragging, dragAtX, dragAtY, true); return }
    if (event.key === Qt.Key_Escape) dismissed()
    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { if (t) activated(t.address) }
    else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
      var by = event.key === Qt.Key_Left ? -1 : 1
      if (!shift) step(by)
      else if (edit) { var o = neighbour(by); if (o) arranged(t.address, o.address, by < 0 ? "before" : "after") }
    }
    else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) cycle(1)
    else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) cycle(-1)
    else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) { if (t) closed(t.address) }
    else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) { if (edit && !t.floating) widthChosen(t.address, Math.round(Desktop.nextWidth(t.share, 1) * 100)) }
    else if (event.key === Qt.Key_Minus) { if (edit && !t.floating) widthChosen(t.address, Math.round(Desktop.nextWidth(t.share, -1) * 100)) }
    else if (event.key === Qt.Key_G) {
      if (edit && shift) pulledOut(t.address)
      else { var n = edit ? neighbour(-1) || neighbour(1) : null; if (n) arranged(t.address, n.address, "pair") }
    }
    else if (event.key === Qt.Key_T) {
      if (!edit) return
      if (t.members.length > 1 && shift) ungrouped(t.address)
      else { var m = neighbour(1) || neighbour(-1); if (m) arranged(t.address, m.address, "group") }
    }
    else if (event.key === Qt.Key_F) { if (edit) floated(t.address) }
    else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
      var id = event.key - Qt.Key_0
      if (workspaces.some(function(w) { return w.id === id })) workspacePicked(id)
    }
    else event.accepted = false
  }

  Keys.onReleased: function(event) { if (event.key === Qt.Key_Shift && dragging !== "") dragMoved(dragging, dragAtX, dragAtY, false) }

  // --- Backdrop ---------------------------------------------------------------

  Rectangle { anchors.fill: parent; color: "#20121e"; opacity: root.progress * 0.9 }
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.dismissed()
    onPositionChanged: function(mouse) { root.pointerX = mouse.x; root.pointerY = mouse.y }
    onWheel: function(wheel) {
      var d = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y
      root.scroll = Math.max(0, Math.min(root.maxScroll, root.scroll - d * 0.9))
    }
  }
  Text {
    x: 48; y: 20
    text: root.appFilter ? "Fenêtres de cette application" : "Mes espaces"
    textFormat: Text.PlainText; color: "#f6e9ef"
    font.family: Style.font.family; font.pixelSize: 22
    opacity: root.progress
    transform: Translate { y: (1 - root.progress) * -14 }
  }

  // --- Workspaces --------------------------------------------------------------

  Flickable {
    id: strip
    x: 48; y: 58; width: parent.width - 96; height: 132
    contentWidth: spaces.width
    opacity: root.progress
    flickableDirection: Flickable.HorizontalFlick
    interactive: contentWidth > width && root.dragging === ""
    Row {
      id: spaces
      y: 8
      spacing: 14
      Repeater {
        id: spaceRepeater
        model: root.workspaces
        Item {
          id: space
          required property var modelData
          required property int index
          readonly property var local: root.windows.filter(function(w) { return w.workspace === space.modelData.id })
          readonly property bool current: root.workspace === modelData.id && !root.appFilter
          readonly property bool aimed: root.dropTarget !== null && root.dropTarget.kind === "workspace" && root.dropTarget.id === modelData.id
          readonly property var mini: Desktop.map(local, root.viewFor(local), { width: frame.width - 14, height: frame.height - 14 }, 0)
          width: 158; height: 116
          // Thumbnails drop in one after the other as the overview opens.
          transform: Translate { y: (1 - root.progress) * -(26 + space.index * 12) }
          Rectangle {
            id: frame
            width: parent.width; height: 92; radius: 16
            y: space.current ? -3 : 0
            color: space.aimed ? "#74445e" : space.current ? "#58364e" : spaceArea.containsMouse ? "#452b3e" : "#362230"
            border.width: 2
            border.color: space.aimed ? "#ffd0e2" : space.current ? "#eaa3c0" : "#65445a"
            scale: space.aimed ? 1.1 : spaceArea.pressed ? 0.96 : spaceArea.containsMouse ? 1.04 : 1
            Behavior on scale { enabled: root.animate; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: root.animate; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: root.animate ? 160 : 0 } }
            Behavior on border.color { ColorAnimation { duration: root.animate ? 160 : 0 } }
            // The workspace in small: same map, same proportions.
            Item {
              x: 7 + (frame.width - 14 - space.mini.width) / 2
              y: 7 + (frame.height - 14 - space.mini.height) / 2
              width: space.mini.width; height: space.mini.height
              Rectangle {
                visible: space.mini.width > space.mini.viewport.width + 2
                x: space.mini.viewport.x; width: space.mini.viewport.width; height: parent.height
                radius: 6; color: Qt.rgba(1, 1, 1, 0.05); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14)
              }
              Repeater {
                model: space.mini.tiles
                ClippingRectangle {
                  id: dot
                  required property var modelData
                  x: modelData.x + 1; y: modelData.y + 1
                  width: Math.max(4, modelData.width - 2); height: Math.max(4, modelData.height - 2)
                  radius: 5
                  color: modelData.window.active ? "#9a6482" : "#714b64"
                  border.width: modelData.members.length > 1 ? 1 : 0; border.color: "#eaa3c0"
                  ScreencopyView {
                    id: miniCopy
                    anchors.fill: parent
                    captureSource: root.capturing && root.progress > 0.1 && root.windows.length <= 10 ? dot.modelData.window.handle : null
                    live: true
                  }
                  Image {
                    anchors.centerIn: parent
                    width: Math.max(8, Math.min(22, parent.width - 6, parent.height - 6)); height: width
                    sourceSize.width: 44; sourceSize.height: 44
                    source: Quickshell.iconPath(dot.modelData.window.icon || "application-x-executable", true)
                    visible: !miniCopy.hasContent
                  }
                }
              }
            }
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 97
            width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
            text: space.modelData.name + (space.local.length ? "  ·  " + space.local.length : "")
            textFormat: Text.PlainText
            color: space.current ? "#f6e9ef" : "#cfb2c2"
            font.family: Style.font.family; font.pixelSize: 11
          }
          MouseArea {
            id: spaceArea
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            // A short pause, so crossing the strip does not flip workspaces.
            onEntered: dwell.restart()
            onExited: dwell.stop()
            onClicked: root.workspaceActivated(space.modelData.id)
          }
          Timer { id: dwell; interval: 140; onTriggered: root.workspacePicked(space.modelData.id) }
        }
      }
      Rectangle {
        id: addSpace
        readonly property bool aimed: root.dropTarget !== null && root.dropTarget.kind === "new"
        width: 66; height: 92; radius: 16
        color: aimed ? "#74445e" : addArea.containsMouse ? "#452b3e" : "#362230"
        border.width: 2; border.color: aimed ? "#ffd0e2" : root.dragging !== "" ? "#eaa3c0" : "#65445a"
        scale: aimed ? 1.12 : addArea.containsMouse ? 1.05 : 1
        transform: Translate { y: (1 - root.progress) * -(26 + spaceRepeater.count * 12) }
        Behavior on scale { enabled: root.animate; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Text {
          anchors.centerIn: parent; text: "+"; color: "#eaa3c0"; font.pixelSize: 30
          // It beats while a window is in hand: this is a place to drop it.
          SequentialAnimation on scale {
            running: root.animate && root.dragging !== ""; loops: Animation.Infinite; alwaysRunToEnd: true
            NumberAnimation { to: 1.3; duration: 420; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 420; easing.type: Easing.InOutSine }
          }
        }
        MouseArea {
          id: addArea
          anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onEntered: root.hint = "Un nouvel espace, tout vide"
          onExited: root.hint = ""
          onClicked: root.workspaceAdded()
        }
      }
    }
  }

  // --- The chosen workspace, to scale -------------------------------------------

  // What is on screen there right now, when the ribbon runs past the screen.
  Rectangle {
    visible: root.plan.editable && root.plan.width > root.plan.viewport.width + 4 && root.shown.length > 0
    x: root.originX + root.plan.viewport.x - root.scroll + root.slide - 3
    y: root.originY - 3
    width: root.plan.viewport.width + 6; height: root.plan.height + 6
    radius: 20
    color: "transparent"
    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.09)
    opacity: root.settled && root.active && !root.moving ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: root.animate ? 180 : 0 } }
    Text {
      x: 14; y: -16
      text: "à l'écran"; textFormat: Text.PlainText
      color: Qt.rgba(1, 1, 1, 0.28); font.family: Style.font.family; font.pixelSize: 10
    }
  }
  // Windows sharing a screen (two halves, or quarters) are framed together.
  Repeater {
    model: root.frames
    Rectangle {
      required property var modelData
      x: root.originX + modelData.x - root.scroll + root.slide - 1
      y: root.originY + modelData.y - 1
      width: modelData.width + 2; height: modelData.height + 2
      radius: 20
      color: Qt.rgba(0.92, 0.64, 0.75, 0.07)
      border.width: 1.5; border.color: Qt.rgba(0.92, 0.64, 0.75, 0.55)
      opacity: 0
      // Rebuilt with each layout: it fades in once the tiles have arrived.
      readonly property bool shown: root.settled && root.active && !root.resizing && !root.moving
      onShownChanged: opacity = shown ? 1 : 0
      Component.onCompleted: opacity = shown ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: root.animate ? 180 : 0 } }
      Text {
        anchors.right: parent.right; anchors.rightMargin: 12; y: -18
        text: modelData.count === 2 ? "Duo" : modelData.count === 3 ? "Trio" : modelData.count === 4 ? "Quatuor" : "Ensemble"
        textFormat: Text.PlainText
        color: "#eaa3c0"; font.family: Style.font.family; font.pixelSize: 11
      }
    }
  }
  Text {
    visible: root.shown.length === 0
    x: root.areaX; y: root.areaY; width: root.areaW; height: root.areaH
    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    text: "Cet espace est libre.\nGlisse une fenêtre sur sa vignette pour l'y envoyer."
    textFormat: Text.PlainText; lineHeight: 1.4
    color: "#cfb2c2"; font.family: Style.font.family; font.pixelSize: 18
    opacity: root.progress
  }
  Repeater {
    model: tiles
    OverviewTile { overview: root }
  }

  // A window pulled away from what it shares: its frame says so.
  Rectangle {
    readonly property bool on: root.dropTarget !== null && root.dropTarget.kind === "out"
    x: root.dragAtX - width / 2; y: root.dragAtY + 34
    z: 70
    width: outText.implicitWidth + 26; height: 30; radius: 15
    color: Qt.rgba(0.13, 0.07, 0.12, 0.92)
    border.width: 1; border.color: "#eaa3c0"
    opacity: on ? 1 : 0
    scale: on ? 1 : 0.9
    Behavior on opacity { NumberAnimation { duration: root.animate ? 120 : 0 } }
    Behavior on scale { enabled: root.animate; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Text {
      id: outText
      anchors.centerIn: parent
      text: "Seule"; textFormat: Text.PlainText
      color: "#f6e9ef"; font.family: Style.font.family; font.pixelSize: 13; font.weight: Font.DemiBold
    }
  }

  // Where the window in hand will land.
  Rectangle {
    id: mark
    readonly property var t: root.dropTarget
    readonly property bool on: t !== null && t.address !== undefined
    readonly property bool side: on && (t.kind === "before" || t.kind === "after")
    property var last: ({ kind: "group", x: 0, y: 0, width: 0, height: 0 })
    onTChanged: if (on) last = t
    // Never null, even for the instant between a target going away and
    // `on` catching up.
    readonly property var g: t !== null && t.address !== undefined ? t : last
    x: g.kind === "before" ? g.x - 5 : g.kind === "after" ? g.x + g.width - 5 : g.kind === "stack" ? g.x + 10 : g.x + g.width * 0.16
    y: g.kind === "stack" ? g.y + g.height * 0.6 : side || !on && (last.kind === "before" || last.kind === "after") ? g.y + 8 : g.y + g.height * 0.16
    width: g.kind === "before" || g.kind === "after" ? 10 : g.kind === "stack" ? g.width - 20 : g.width * 0.68
    height: g.kind === "before" || g.kind === "after" ? g.height - 16 : g.kind === "stack" ? g.height * 0.4 - 10 : g.height * 0.68
    z: 55
    radius: side ? 5 : 16
    color: side ? "#ffd0e2" : Qt.rgba(0.92, 0.64, 0.75, 0.3)
    border.width: side ? 0 : 2; border.color: "#ffd0e2"
    opacity: on ? 1 : 0
    scale: on ? 1 : 0.8
    Behavior on opacity { NumberAnimation { duration: root.animate ? 120 : 0 } }
    Behavior on scale { enabled: root.animate; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Row {
      anchors.centerIn: parent; spacing: 7
      visible: !mark.side && mark.width > 110 && mark.height > 30
      DivaGlyph { name: mark.g.kind === "stack" || mark.g.kind === "tabs" ? "layers" : "grid"; family: Style.font.family; size: 16; color: "#f6e9ef"; anchors.verticalCenter: parent.verticalCenter }
      Text {
        text: mark.g.kind === "stack" ? "Empiler" : mark.g.kind === "tabs" ? "Onglets" : mark.g.kind === "pair" ? "Côte à côte"
          : mark.g.kind === "quarter" ? "Un quart" : "À côté"
        textFormat: Text.PlainText; color: "#f6e9ef"
        font.family: Style.font.family; font.pixelSize: 14; font.weight: Font.DemiBold
        anchors.verticalCenter: parent.verticalCenter
      }
    }
    SequentialAnimation on border.width {
      running: root.animate && mark.on && !mark.side; loops: Animation.Infinite
      NumberAnimation { to: 3; duration: 380 }
      NumberAnimation { to: 2; duration: 380 }
    }
  }

  // --- Diva, in the corner, saying what a gesture will do -------------------------

  DivaAvatar {
    id: avatar
    width: 62; height: 62
    x: parent.width - 48 - width
    y: parent.height - 78 + (1 - root.progress) * 40
    opacity: root.progress
    animate: root.animate
    mood: root.sorry ? "sad" : root.cheering ? "happy" : root.resizing ? "focus" : root.dragging !== "" ? "curious" : "idle"
    lookX: Math.max(-1, Math.min(1, (root.pointerX - (x + width / 2)) / 420))
    lookY: Math.max(-1, Math.min(1, (root.pointerY - (y + height / 2)) / 300))
    near: 0.5
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: avatar.poke() }
  }
  DivaBubble {
    id: bubble
    readonly property string words: root.hint || root.status
      || (root.appFilter ? "Clique une fenêtre pour y aller, ou glisse-la vers un espace."
          : "Glisse une fenêtre sur une autre pour partager l'écran, ou tire son bord.")
    side: "right"
    width: said.width + 34 + tail
    height: Math.max(40, said.implicitHeight + 20)
    x: avatar.x - width - 4
    y: avatar.y + (avatar.height - height) / 2
    radius: 20; tail: 9
    fill: Qt.rgba(0.17, 0.11, 0.16, 0.86)
    line: Qt.rgba(1, 1, 1, 0.16)
    opacity: root.progress
    Text {
      id: said
      x: bubble.bodyX + 17
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(implicitWidth, Math.max(120, root.width * 0.42))
      text: bubble.words
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      color: "#f6e9ef"
      font.family: Style.font.family; font.pixelSize: 13
    }
  }
  Text {
    x: 48
    anchors.verticalCenter: avatar.verticalCenter
    width: Math.max(0, bubble.x - 72)
    visible: width > 260
    text: root.appFilter ? "←  →  choisir    Entrée  ouvrir    Échap  revenir"
      : "←  →  choisir    Maj + ←  →  déplacer    +  −  largeur    G  côte à côte    Maj + G  séparer    T  onglets    Suppr  fermer    Tab  espace suivant"
    textFormat: Text.PlainText
    wrapMode: Text.WordWrap
    color: "#9c8291"
    font.family: Style.font.family; font.pixelSize: 11
    opacity: root.progress
  }
}
