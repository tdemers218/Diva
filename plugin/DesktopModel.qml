import QtQuick
import Quickshell
import Quickshell.Hyprland
import "core/Desktop.js" as Desktop

Item {
  id: root
  property var windows: []
  property var apps: []
  property var pins: null
  property var dock: []
  property string windowSignature: ""
  property string appSignature: ""
  property string dockSignature: ""
  // While the overview is open, geometry is re-read from Hyprland often
  // enough for a resize or a regrouping to show at once.
  property bool live: false
  function refresh() { Hyprland.refreshToplevels(); Hyprland.refreshMonitors(); settle.restart() }
  function update() {
    var entries = (DesktopEntries.applications.values || []).filter(function(e) { return e && !e.noDisplay })
    var nextApps = entries.map(function(e) { return { id: String(e.id), name: String(e.name), icon: String(e.icon || ""), startupClass: String(e.startupClass || "") } })
    var nextAppSignature = JSON.stringify(nextApps)
    if (nextAppSignature !== appSignature) { apps = nextApps; appSignature = nextAppSignature }
    var nextWindows = (Hyprland.toplevels.values || []).filter(function(t) { return t.workspace && t.workspace.id > 0 }).map(function(t) {
      var c = t.lastIpcObject || ({})
      var cls = String(c.class || (t.wayland ? t.wayland.appId : "") || "Application")
      var app = Desktop.appFor(cls, root.apps)
      return { address: "0x" + String(t.address).replace(/^0x/, ""), cls: cls, title: String(t.title || cls), icon: app ? app.icon : "application-x-executable", workspace: t.workspace.id, active: t.activated, handle: t.wayland, at: c.at || [0,0], size: c.size || [800,600], monitor: t.monitor ? t.monitor.name : "",
        floating: !!c.floating, grouped: (c.grouped || []).map(String), recent: c.focusHistoryID === undefined ? 0 : c.focusHistoryID }
    })
    var nextWindowSignature = JSON.stringify(nextWindows.map(function(w) { return [w.address,w.cls,w.title,w.workspace,w.active,w.at,w.size,w.monitor,!!w.handle,w.floating,w.grouped,w.recent] }))
    if (nextWindowSignature !== windowSignature) { windows = nextWindows; windowSignature = nextWindowSignature }
    var pinned = root.pins
    if (!Array.isArray(pinned)) {
      pinned = []
      var browser = apps.find(function(a) { return /^(brave-browser|brave|chromium|firefox|google-chrome)$/.test(Desktop.key(a.id)) })
      var files = Desktop.appFor("org.gnome.Nautilus", apps)
      if (browser) pinned.push(browser.id)
      if (files) pinned.push(files.id)
    }
    var signature = windowSignature + appSignature + JSON.stringify(pinned)
    if (signature !== dockSignature) { dock = Desktop.dock(windows, apps, pinned); dockSignature = signature }
  }
  Component.onCompleted: update()
  // Snapshots are taken from timers, outside native model destruction
  // signals, so repeaters never read a Wayland object during its removal
  // callback. They are driven by what Hyprland reports rather than by a fast
  // poll: an idle desktop does no work here beyond a slow safety tick, which
  // also catches what Hyprland does not announce (a column moved by a
  // keyboard shortcut) and newly installed applications.
  Timer { interval: 5000; repeat: true; running: true; onTriggered: root.refresh() }
  Timer { interval: 320; repeat: true; running: root.live; onTriggered: root.refresh() }
  // The dock follows the order of the windows, so positions are re-read
  // whenever Hyprland reports that something moved, opened, closed or took focus.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      // A title that changes (a terminal's spinner does, every second) needs
      // no new geometry: one cheap snapshot a second at most. Anything else
      // re-reads positions, at most four times a second.
      if (String(event.name).indexOf("windowtitle") === 0) { if (!titled.running) titled.start() }
      else if (!moved.running) moved.start()
    }
  }
  Timer { id: moved; interval: 250; onTriggered: root.refresh() }
  Timer { id: titled; interval: 1000; onTriggered: root.update() }
  Timer { id: settle; interval: 90; onTriggered: root.update() }
}
