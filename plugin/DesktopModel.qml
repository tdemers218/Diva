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
  function update() {
    var entries = (DesktopEntries.applications.values || []).filter(function(e) { return e && !e.noDisplay })
    var nextApps = entries.map(function(e) { return { id: String(e.id), name: String(e.name), icon: String(e.icon || ""), startupClass: String(e.startupClass || "") } })
    var nextAppSignature = JSON.stringify(nextApps)
    if (nextAppSignature !== appSignature) { apps = nextApps; appSignature = nextAppSignature }
    var nextWindows = (Hyprland.toplevels.values || []).filter(function(t) { return t.workspace && t.workspace.id > 0 }).map(function(t) {
      var c = t.lastIpcObject || ({})
      var cls = String(c.class || (t.wayland ? t.wayland.appId : "") || "Application")
      var app = Desktop.appFor(cls, root.apps)
      return { address: "0x" + String(t.address).replace(/^0x/, ""), cls: cls, title: String(t.title || cls), icon: app ? app.icon : "application-x-executable", workspace: t.workspace.id, active: t.activated, handle: t.wayland, at: c.at || [0,0], size: c.size || [800,600], monitor: t.monitor ? t.monitor.name : "" }
    })
    var nextWindowSignature = JSON.stringify(nextWindows.map(function(w) { return [w.address,w.cls,w.title,w.workspace,w.active,w.at,w.size,w.monitor,!!w.handle] }))
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
  // Snapshot outside native model destruction signals; prevents repeaters
  // from reading a Wayland object during its removal callback.
  Timer { interval: 700; repeat: true; running: true; onTriggered: root.update() }
}
