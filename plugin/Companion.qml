import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons

// Diva on the desktop: she sits on the wallpaper, behind the windows, says
// hello when the session starts, glances around now and then, dozes at
// night, warns about a low battery, and opens her menu when clicked. She can
// be picked up and put down anywhere on the desktop; she remembers where.
// She only moves in short bursts, so an idle desktop stays idle.
Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  readonly property string home: Quickshell.env("HOME")
  readonly property string pluginId: (manifest && manifest.id) || "io.github.tdemers218.diva"
  readonly property string pluginDir: decodeURIComponent(String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")).replace(/\/$/, "")

  property var config: ({})
  // "companion": false in ~/.config/diva/config.json hides her.
  readonly property bool wanted: config.companion !== false
  readonly property bool motion: config.animations !== false
  // What she is saying in her bubble; "" when quiet.
  property string line: ""
  property bool hovered: false
  // A short moment of life: a glance, a blink.
  property bool burst: false
  property real lookX: 0
  property real lookY: 0
  property bool loved: false
  property bool warned: false
  property bool dragging: false
  // How hard Diva is saving the battery (bin/diva-power): 0 none .. 3 low
  // power mode. -1 until the first reading.
  property int saving: -1
  // Where she was put down, as fractions of the screen (0..1); -1 until she
  // has been moved, which leaves her in the bottom-right corner.
  property real placeX: -1
  property real placeY: -1
  property int hour: new Date().getHours()

  readonly property bool night: hour >= 23 || hour < 6
  // On battery she keeps still unless someone is with her.
  readonly property bool lively: motion && (hovered || line !== "" || (burst && saving <= 0) || loved || dragging)
  readonly property string mood: dragging ? "curious" : loved ? "love" : line !== "" ? "happy" : hovered ? "shy" : night ? "sleepy" : "idle"
  readonly property string voice: fredoka.status === FontLoader.Ready ? fredoka.font.family : Style.font.family

  function say(text, ms) {
    root.line = text
    quiet.interval = ms || 6000
    quiet.restart()
  }

  function greet() {
    var name = String(config.name || "").trim()
    var hello = hour < 5 ? "Encore debout" : hour < 12 ? "Bonjour" : hour < 18 ? "Coucou" : "Bonsoir"
    root.say(hello + (name ? " " + name : "") + (hour < 5 ? " ?" : " !") + " Je suis là si tu as besoin.", 7000)
  }

  readonly property var purrs: ["Mmh, encore.", "Hi hi, c'est doux.", "J'adore ça.", "Tu vas me faire ronronner."]
  function petted() {
    avatar.pet()
    root.loved = true
    calm.restart()
    root.say(root.purrs[Math.floor(Math.random() * root.purrs.length)], 2500)
  }

  // bin/diva-power moved to another level: say so, once, in a few words.
  function powered(text) {
    var r = null
    try { r = JSON.parse(String(text).trim()) } catch (e) { r = null }
    if (!r || r.ok !== true) return
    var was = root.saving
    root.saving = r.level
    if (was < 0 || was === r.level) return
    if (r.level === 0) root.say("Merci de m'avoir branchée. Je remets tout comme avant.", 5000)
    else if (r.level === 3) root.say("Batterie faible : je passe en mode économie. Branche-moi quand tu peux.", 9000)
    else if (r.level === 2 && was < 2) root.say("Je fais attention à la batterie. Tu ne verras presque rien.", 6000)
  }

  function clicked() {
    avatar.poke()
    root.loved = true
    calm.restart()
    openMenu.restart()
  }

  // Remember where she was dropped, outside the pack's checkout.
  function place(x, y) {
    root.placeX = Math.max(0, Math.min(1, x))
    root.placeY = Math.max(0, Math.min(1, y))
    placeFile.setText(JSON.stringify({ x: root.placeX, y: root.placeY }) + "\n")
  }

  FileView {
    id: placeFile
    path: root.home + "/.local/state/diva/companion.json"
    printErrors: false
    onLoaded: {
      try {
        var p = JSON.parse(text())
        if (p && p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1) { root.placeX = p.x; root.placeY = p.y }
      } catch (e) {}
    }
  }

  FontLoader { id: fredoka; source: Qt.resolvedUrl("fonts/Fredoka.ttf") }

  Timer { id: quiet; onTriggered: root.line = "" }
  Timer { id: calm; interval: 1500; onTriggered: root.loved = false }
  Timer {
    id: openMenu
    interval: 320
    onTriggered: Quickshell.execDetached(["omarchy-shell", "shell", "toggle", root.pluginId, "{}"])
  }
  // Hello, a few seconds after the desktop is up.
  Timer { interval: 3500; running: root.wanted; onTriggered: root.greet() }
  // Every so often: a glance somewhere, then back.
  Timer {
    interval: 13000
    repeat: true
    running: root.wanted && root.motion && !root.night
    onTriggered: {
      root.hour = new Date().getHours()
      root.lookX = Math.random() * 1.6 - 0.8
      root.lookY = Math.random() * 0.8 - 0.5
      root.burst = true
      settle.restart()
    }
  }
  Timer { id: settle; interval: 3200; onTriggered: { root.burst = false; root.lookX = 0; root.lookY = 0 } }
  // Battery care, every half minute: cheap to ask, and plugging in or out is
  // noticed quickly.
  Timer { interval: 30000; repeat: true; running: true; triggeredOnStart: true; onTriggered: if (!power.running) power.running = true }
  Process {
    id: power
    command: [root.pluginDir + "/bin/diva-power", "apply"]
    stdout: StdioCollector { onStreamFinished: root.powered(text) }
  }
  PetDetector { id: petting; onPetted: root.petted() }

  // Her screensaver. Omarchy's own is switched off by the pack (its toggle),
  // so Diva starts hers after the same idle time Omarchy is set to use.
  property int screensaverAfter: 150
  FileView {
    path: root.home + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var seconds = Number(JSON.parse(text()).idle.screensaver)
        if (seconds >= 10) root.screensaverAfter = seconds
      } catch (e) {}
    }
  }
  IdleMonitor {
    enabled: root.config.screensaver !== false
    timeout: root.screensaverAfter
    respectInhibitors: true
    onIsIdleChanged: if (isIdle) Quickshell.execDetached([root.pluginDir + "/bin/diva-screensaver-launch"])
  }

  // Battery, every few minutes; she speaks up once when it runs low.
  Timer { interval: 180000; repeat: true; running: root.wanted; triggeredOnStart: true; onTriggered: state.running = true }
  Process {
    id: state
    command: [root.pluginDir + "/bin/diva-state"]
    stdout: StdioCollector {
      onStreamFinished: {
        var s = null
        try { s = JSON.parse(String(text).trim()) } catch (e) { s = null }
        if (!s || s.battery < 0) return
        if (s.charging || s.battery > 20) { root.warned = false; return }
        if (!root.warned && root.saving < 3) {
          root.warned = true
          root.say("Il ne reste que " + s.battery + " % de batterie. Tu me branches ?", 12000)
        }
      }
    }
  }

  FileView {
    path: root.home + "/.config/diva/config.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.config = JSON.parse(text()) || ({}) } catch (e) { root.config = ({}) }
    }
    onLoadFailed: root.config = ({})
  }

  PanelWindow {
    id: desk
    visible: root.wanted
    // The whole desktop is hers to be placed on, but only Diva herself
    // takes clicks: everything else stays the desktop's.
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "diva-companion"
    // Above the wallpaper, below every window.
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // ...except while she is being carried: then the whole desktop follows
    // the pointer, so a fast move cannot outrun her and drop her.
    mask: grab.pressed ? null : onlyDiva
    // Diva and a little air around her, where a shaken pointer pets her.
    Region { id: onlyDiva; item: halo }

    // Room left for the bar, whichever edge it is on.
    readonly property int edge: Style.space(40)
    readonly property real maxX: Math.max(0, width - avatar.width - Style.space(8))
    readonly property real maxY: Math.max(edge, height - avatar.height - edge)
    readonly property bool onRight: avatar.x + avatar.width / 2 > width / 2

    DivaBubble {
      id: bubble
      // On the side where there is room, its tail toward her.
      side: desk.onRight ? "right" : "left"
      x: desk.onRight ? avatar.x - width - Style.space(2) : avatar.x + avatar.width + Style.space(2)
      y: Math.max(Style.space(8), Math.min(desk.height - height - Style.space(8), avatar.y + (avatar.height - height) / 2))
      width: Math.min(Style.space(280), said.implicitWidth + Style.space(34)) + tail
      height: said.implicitHeight + Style.space(22)
      radius: Style.space(20)
      tail: Style.space(9)
      fill: Qt.rgba(0.17, 0.11, 0.16, 0.82)
      line: Qt.rgba(1, 1, 1, 0.16)
      opacity: root.line !== "" && !root.dragging ? 1 : 0
      scale: root.line !== "" && !root.dragging ? 1 : 0.85
      transformOrigin: desk.onRight ? Item.Right : Item.Left
      Behavior on opacity { NumberAnimation { duration: root.motion ? 220 : 0 } }
      Behavior on scale { NumberAnimation { duration: root.motion ? 260 : 0; easing.type: Easing.OutBack } }

      Text {
        id: said
        textFormat: Text.PlainText
        x: bubble.bodyX + Style.space(17)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Style.space(246))
        text: root.line
        color: "#f6e9ef"
        font.family: root.voice
        font.pixelSize: Style.space(15)
        wrapMode: Text.WordWrap
      }
    }

    Item {
      id: halo
      readonly property int air: Style.space(46)
      x: avatar.x - air
      y: avatar.y - air
      width: avatar.width + air * 2
      height: avatar.height + air * 2
      HoverHandler {
        onPointChanged: petting.feed(point.position.x)
        onHoveredChanged: if (!hovered) petting.forget()
      }
    }

    DivaAvatar {
      id: avatar
      width: Style.space(96)
      height: width
      // Bottom-right until she is moved; then wherever she was put down.
      x: grab.drag.active ? x : (root.placeX < 0 ? desk.maxX - Style.space(14) : root.placeX * desk.maxX)
      y: grab.drag.active ? y : (root.placeY < 0 ? desk.maxY - Style.space(8) : desk.edge + root.placeY * (desk.maxY - desk.edge))
      mood: root.mood
      animate: root.lively
      lookX: root.hovered ? pointer.lookX : root.lookX
      lookY: root.hovered ? pointer.lookY : root.lookY
      near: root.hovered ? 0.8 : 0
      opacity: root.hovered || root.line !== "" || root.loved || root.dragging ? 1 : 0.88
      // Lifted a little while she is carried.
      scale: root.dragging ? 1.12 : 1
      Behavior on opacity { NumberAnimation { duration: 200 } }
      Behavior on scale { NumberAnimation { duration: root.motion ? 160 : 0; easing.type: Easing.OutBack } }

      HoverHandler {
        id: pointer
        readonly property real lookX: Math.max(-1, Math.min(1, (point.position.x - avatar.width / 2) / (avatar.width / 2)))
        readonly property real lookY: Math.max(-1, Math.min(1, (point.position.y - avatar.height / 2) / (avatar.height / 2)))
        onHoveredChanged: {
          root.hovered = hovered
          if (hovered && root.line === "" && !root.dragging) root.say("Clique-moi, ou attrape-moi pour me déplacer.", 3500)
        }
      }

      // One press does both: a click opens her menu, a drag carries her.
      MouseArea {
        id: grab
        anchors.fill: parent
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        drag.target: avatar
        drag.threshold: Style.space(8)
        drag.minimumX: 0
        drag.maximumX: desk.maxX
        drag.minimumY: desk.edge
        drag.maximumY: desk.maxY
        drag.onActiveChanged: {
          root.dragging = drag.active
          if (drag.active) { root.line = ""; return }
          // Put down: remember the spot, and settle with a little hop.
          root.place(desk.maxX > 0 ? avatar.x / desk.maxX : 1,
                     desk.maxY > desk.edge ? (avatar.y - desk.edge) / (desk.maxY - desk.edge) : 1)
          avatar.poke()
          root.say("Ici, c'est parfait.", 2500)
        }
        onClicked: root.clicked()
      }
    }
  }
}
