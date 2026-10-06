import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "core/Desktop.js" as Desktop

Item {
  id: root
  property var config: ({})
  property bool opened: false
  property real progress: opened ? 1 : 0
  property var activeScreen: Quickshell.screens[0] || null
  property int workspace: 1
  property string appFilter: ""
  property var extraSpaces: []
  property string status: ""
  property bool statusOk: true
  property int statusTick: 0
  // The workspace on screen when the overview opened.
  property int homeWorkspace: 1
  property bool edgeReady: true
  property string pendingAddress: ""
  property int pendingWorkspace: 0
  readonly property string pluginDir: decodeURIComponent(String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")).replace(/\/$/, "")
  readonly property var workspaces: {
    // Each workspace once: the chosen one may also be a placeholder or live.
    var ids = [], result = []
    var live = Hyprland.workspaces.values || []
    ;[root.workspace].concat(root.extraSpaces).concat(live.map(function(w) { return w.id })).forEach(function(id) {
      if (id > 0 && ids.indexOf(id) < 0) ids.push(id)
    })
    ids.sort(function(a,b) { return a-b })
    ids.forEach(function(id) { var w = live.find(function(v) { return v.id === id }); result.push({id:id,name:w && w.name !== String(id) ? w.name : "Espace " + id}) })
    return result
  }
  readonly property var monitor: (Hyprland.monitors.values || []).find(function(m) { return root.activeScreen && m.name === root.activeScreen.name }) || null
  // Each screen's rectangle in layout coordinates, for drawing a workspace to scale.
  readonly property var views: {
    var result = {}
    ;(Hyprland.monitors.values || []).forEach(function(m) {
      var c = m.lastIpcObject || ({})
      if (!c.width) return
      var scale = c.scale || 1, turned = (c.transform || 0) % 2 === 1
      result[m.name] = { x: c.x || 0, y: c.y || 0, width: (turned ? c.height : c.width) / scale, height: (turned ? c.width : c.height) / scale }
    })
    return result
  }
  readonly property var windows: desktopModel.windows.map(function(w) { var a = Desktop.appFor(w.cls, desktopModel.apps); var n = Object.assign({}, w); n.appId = a ? a.id : w.cls; return n })
  DesktopModel { id: desktopModel; live: root.opened }
  FileView {
    path: Quickshell.env("HOME") + "/.config/diva/config.json"
    watchChanges: true; printErrors: false
    onFileChanged: reload()
    onLoaded: { try { root.config = JSON.parse(text()) } catch(e) {} }
  }
  Behavior on progress { NumberAnimation { duration: root.config.animations === false ? 0 : root.opened ? 300 : 230; easing.type: Easing.InOutCubic } }
  function showOn(screen, app) {
    if (root.opened) return
    closeDelay.stop(); pendingAddress = ""; pendingWorkspace = 0
    Hyprland.refreshToplevels()
    Hyprland.refreshWorkspaces()
    desktopModel.update()
    activeScreen = screen || Quickshell.screens[0]
    var focused = Hyprland.focusedWorkspace
    workspace = focused && focused.id > 0 ? focused.id : 1
    homeWorkspace = workspace
    extraSpaces = []
    appFilter = app || ""; status = ""; opened = true
    Qt.callLater(function() { overview.forceActiveFocus() })
  }
  function show() {
    var m = Hyprland.focusedMonitor
    showOn(Quickshell.screens.find(function(s) { return m && s.name === m.name }) || Quickshell.screens[0], "")
  }
  function hide() { opened = false; closeDelay.restart() }
  // Window changes asked for in the overview run one at a time, in order.
  property var queue: []
  function act(args, done) { queue = queue.concat([{ args: args, done: done }]); pump() }
  function pump() {
    if (change.running || !queue.length) return
    var next = queue[0]
    queue = queue.slice(1)
    change.done = next.done
    change.command = [root.pluginDir + "/bin/diva-window"].concat(next.args).concat(["--now"])
    change.running = true
  }
  function freeSpace() {
    var used = root.workspaces.map(function(w) { return w.id })
    var id = 1
    while (used.indexOf(id) >= 0 && id <= 100) id++
    return id > 100 ? 0 : id
  }
  IpcHandler {
    target: "diva.desktop"
    function status(): string {
      return JSON.stringify({ opened: root.opened, screens: Quickshell.screens.length,
        windows: root.windows.length, workspace: root.workspace,
        hotEdge: root.config.overviewHotEdge !== false, edgeReady: root.edgeReady })
    }
    function show(): void { root.show() }
    function hide(): void { root.hide() }
    function toggle(): void { root.opened ? root.hide() : root.show() }
    function showApp(id: string): void {
      root.show()
      root.appFilter = id
    }
    function select(number: int): void { root.appFilter = ""; root.workspace = number }
    // A drag, replayed for checks: pick a window up and let it go at a point.
    function drop(address: string, x: int, y: int, tabs: bool): string {
      overview.dragBegan(address); overview.dragMoved(address, x, y, tabs)
      var target = overview.dropTarget ? overview.dropTarget.kind + " " + (overview.dropTarget.address || overview.dropTarget.id || "") : "nothing"
      overview.dragEnded(address)
      return target
    }
    // The map as drawn, for checks: one line per tile.
    function map(): string {
      return JSON.stringify({ scale: overview.plan.scale, width: overview.plan.width, area: overview.areaW,
        tiles: overview.plan.tiles.map(function(t) {
          return { address: t.address, title: t.window.title, x: Math.round(overview.originX + t.x - overview.scroll), y: Math.round(overview.originY + t.y),
                   width: Math.round(t.width), height: Math.round(t.height), column: t.column, row: t.row, tabs: t.members.length, floating: t.floating } }) })
    }
  }
  Timer {
    id: closeDelay; interval: root.config.animations === false ? 1 : 260
    onTriggered: {
      if (root.pendingAddress) Quickshell.execDetached([root.pluginDir + "/bin/diva-window", "focus", root.pendingAddress, "--now"])
      else if (root.pendingWorkspace) Quickshell.execDetached([root.pluginDir + "/bin/diva-window", "goto-workspace", String(root.pendingWorkspace), "--now"])
      root.pendingAddress = ""; root.pendingWorkspace = 0
    }
  }
  // A change that never returns must not keep the keyboard away from the
  // overview (Escape would stop working): it is abandoned after a few seconds.
  Timer { interval: 5000; running: change.running; onTriggered: change.running = false }
  // What Diva said about the last change fades back to her usual tip.
  Timer { id: forget; interval: 3600; onTriggered: root.status = "" }
  Process {
    id: change
    property string done: ""
    onExited: function(code) {
      root.statusOk = code === 0
      root.status = code === 0 ? done : "Je n'ai pas réussi cette fois, désolée."
      root.statusTick++
      forget.restart()
      desktopModel.refresh()
      root.pump()
    }
  }
  // Re-arm only after the pointer leaves the screen edge; closing while
  // the pointer is still at the top must not reopen the overview immediately.
  Timer { interval: 250; repeat: true; running: !root.opened && !root.edgeReady; onTriggered: if (!cursorPosition.running) cursorPosition.running = true }
  Process {
    id: cursorPosition
    command: ["hyprctl", "cursorpos", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var pos = JSON.parse(text)
          var atTop = (Hyprland.monitors.values || []).some(function(m) {
            var c = m.lastIpcObject || ({})
            return pos.x >= c.x && pos.x < c.x + c.width / (c.scale || 1) && pos.y >= c.y && pos.y < c.y + 3
          })
          if (!atTop) root.edgeReady = true
        } catch(e) {}
      }
    }
  }
  Variants {
    model: Quickshell.screens
    PanelWindow {
      id: edge
      required property var modelData
      screen: modelData
      visible: !root.opened && root.progress < 0.01 && root.config.overviewHotEdge !== false
      anchors { top: true; left: true; right: true }
      implicitHeight: 2
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "diva-hot-edge"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      MouseArea {
        anchors.fill: parent; hoverEnabled: true
        onEntered: dwell.restart()
        onExited: dwell.stop()
      }
      Timer { id: dwell; interval: 250; onTriggered: if (root.edgeReady) { root.edgeReady = false; root.showOn(edge.modelData, "") } }
    }
  }
  PanelWindow {
    id: panel
    screen: root.activeScreen
    visible: root.opened || root.progress > 0.01
    anchors { top:true; bottom:true; left:true; right:true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "diva-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    // Hyprland will not focus a window while a panel holds the keyboard, and
    // rearranging a column needs that focus: let go for the time of a change.
    WlrLayershell.keyboardFocus: root.opened && !change.running ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    OverviewView {
      id: overview
      anchors.fill: parent
      windows: root.windows
      workspaces: root.workspaces
      workspace: root.workspace
      appFilter: root.appFilter
      progress: root.progress
      status: root.status
      statusOk: root.statusOk
      statusTick: root.statusTick
      homeWorkspace: root.homeWorkspace
      active: root.opened
      animate: root.config.animations !== false
      views: root.views
      capturing: panel.visible
      monitorName: root.activeScreen ? root.activeScreen.name : ""
      monitorX: root.monitor ? root.monitor.lastIpcObject.x || 0 : 0
      monitorY: root.monitor ? root.monitor.lastIpcObject.y || 0 : 0
      onWorkspacePicked: function(number) { root.appFilter = ""; root.workspace = number }
      onDismissed: root.hide()
      onActivated: function(address) { root.pendingAddress = address; root.hide() }
      onWorkspaceActivated: function(number) { root.pendingWorkspace = number; root.hide() }
      onWindowMoved: function(address, number) { root.act(["move-address", address, String(number)], "Voilà, elle est dans son nouvel espace.") }
      onWindowToNewWorkspace: function(address) {
        var id = root.freeSpace()
        if (!id) return
        root.extraSpaces = root.extraSpaces.concat([id])
        root.act(["move-address", address, String(id)], "Un espace rien que pour elle.")
      }
      onArranged: function(address, target, how) {
        root.act(["arrange", address, target, how], how === "group" ? "En onglets : elles partagent la même place."
          : how === "pair" ? "Voilà, elles se partagent l'écran."
          : how === "stack" ? "Empilées l'une sous l'autre." : "Rangée ici.")
      }
      onWidthChosen: function(address, percent) { root.act(["width", address, String(percent)], "Nouvelle largeur.") }
      onResizedBy: function(address, dx, dy) { root.act(["resize-address", address, String(dx), String(dy)], "Nouvelle taille.") }
      onClosed: function(address) { root.act(["close-address", address], "Fenêtre fermée.") }
      onFloated: function(address) { root.act(["float-address", address], "C'est fait.") }
      onUngrouped: function(address) { root.act(["ungroup", address], "Elle a retrouvé sa propre place.") }
      onPulledOut: function(address) { root.act(["alone", address], "Voilà, elle a retrouvé sa place à elle.") }
      onUnstacked: function(address) { root.act(["own-column", address], "Elle a sa colonne à elle.") }
      onWorkspaceAdded: {
        var id = root.freeSpace()
        if (!id) return
        root.extraSpaces = root.extraSpaces.concat([id]); root.workspace = id; root.appFilter = ""
      }
    }
  }
}
