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
  property bool edgeReady: true
  property string pendingAddress: ""
  property int pendingWorkspace: 0
  readonly property string pluginDir: decodeURIComponent(String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")).replace(/\/$/, "")
  readonly property var workspaces: {
    var ids = [root.workspace].concat(root.extraSpaces)
    var result = []
    var live = Hyprland.workspaces.values || []
    live.forEach(function(w) { if (w.id > 0 && ids.indexOf(w.id) < 0) ids.push(w.id) })
    ids.sort(function(a,b) { return a-b })
    ids.forEach(function(id) { var w = live.find(function(v) { return v.id === id }); result.push({id:id,name:w && w.name !== String(id) ? w.name : "Espace " + id}) })
    return result
  }
  readonly property var monitor: (Hyprland.monitors.values || []).find(function(m) { return root.activeScreen && m.name === root.activeScreen.name }) || null
  readonly property var windows: desktopModel.windows.map(function(w) { var a = Desktop.appFor(w.cls, desktopModel.apps); var n = Object.assign({}, w); n.appId = a ? a.id : w.cls; return n })
  DesktopModel { id: desktopModel }
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
    appFilter = app || ""; status = ""; opened = true
    Qt.callLater(function() { overview.forceActiveFocus() })
  }
  function show() {
    var m = Hyprland.focusedMonitor
    showOn(Quickshell.screens.find(function(s) { return m && s.name === m.name }) || Quickshell.screens[0], "")
  }
  function hide() { opened = false; closeDelay.restart() }
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
  }
  Timer {
    id: closeDelay; interval: root.config.animations === false ? 1 : 260
    onTriggered: {
      if (root.pendingAddress) Quickshell.execDetached([root.pluginDir + "/bin/diva-window", "focus", root.pendingAddress, "--now"])
      else if (root.pendingWorkspace) Quickshell.execDetached([root.pluginDir + "/bin/diva-window", "goto-workspace", String(root.pendingWorkspace), "--now"])
      root.pendingAddress = ""; root.pendingWorkspace = 0
    }
  }
  Process {
    id: moveWindow
    onExited: function(code) { root.status = code === 0 ? "Fenêtre déplacée." : "Impossible de déplacer cette fenêtre."; desktopModel.update() }
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
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    OverviewView {
      id: overview
      anchors.fill: parent
      windows: root.windows
      workspaces: root.workspaces
      workspace: root.workspace
      appFilter: root.appFilter
      progress: root.progress
      status: root.status
      capturing: panel.visible
      monitorName: root.activeScreen ? root.activeScreen.name : ""
      monitorX: root.monitor ? root.monitor.lastIpcObject.x || 0 : 0
      monitorY: root.monitor ? root.monitor.lastIpcObject.y || 0 : 0
      onWorkspaceChanged: root.workspace = workspace
      onAppFilterChanged: root.appFilter = appFilter
      onDismissed: root.hide()
      onActivated: function(address) { root.pendingAddress = address; root.hide() }
      onWorkspaceActivated: function(number) { root.pendingWorkspace = number; root.hide() }
      onWindowMoved: function(address,number) {
        if (moveWindow.running) return
        moveWindow.command = [root.pluginDir + "/bin/diva-window", "move-address", address, String(number), "--now"]
        moveWindow.running = true
      }
      onWorkspaceAdded: {
        var used = root.workspaces.map(function(w) { return w.id })
        var id = 1
        while (used.indexOf(id) >= 0 && id <= 100) id++
        if (id > 100) return
        root.extraSpaces = root.extraSpaces.concat([id]); root.workspace = id; root.appFilter = ""
      }
    }
  }
}
