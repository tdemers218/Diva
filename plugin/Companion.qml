import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons

// Diva on the desktop: she sits in the corner of the wallpaper, behind the
// windows, says hello when the session starts, glances around now and then,
// dozes at night, warns about a low battery, and opens her menu when
// clicked. She only moves in short bursts, so an idle desktop stays idle.
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
  property int hour: new Date().getHours()

  readonly property bool night: hour >= 23 || hour < 6
  readonly property bool lively: motion && (hovered || line !== "" || burst || loved)
  readonly property string mood: loved ? "love" : line !== "" ? "happy" : hovered ? "shy" : night ? "sleepy" : "idle"
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

  function clicked() {
    avatar.poke()
    root.loved = true
    calm.restart()
    openMenu.restart()
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
        if (!root.warned) {
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
    id: corner
    visible: root.wanted
    anchors { right: true; bottom: true }
    margins { right: Style.space(22); bottom: Style.space(18) }
    implicitWidth: Style.space(380)
    implicitHeight: Style.space(124)
    color: "transparent"
    WlrLayershell.namespace: "diva-companion"
    // Above the wallpaper, below every window.
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Only Diva herself takes clicks; the rest of the corner stays the desktop's.
    mask: Region { item: avatar }

    Rectangle {
      id: bubble
      anchors.right: avatar.left
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: avatar.verticalCenter
      width: Math.min(corner.width - avatar.width - Style.space(14), said.implicitWidth + Style.space(34))
      height: said.implicitHeight + Style.space(22)
      radius: Style.space(20)
      color: Qt.rgba(0.17, 0.11, 0.16, 0.82)
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.16)
      opacity: root.line !== "" ? 1 : 0
      scale: root.line !== "" ? 1 : 0.85
      transformOrigin: Item.Right
      Behavior on opacity { NumberAnimation { duration: root.motion ? 220 : 0 } }
      Behavior on scale { NumberAnimation { duration: root.motion ? 260 : 0; easing.type: Easing.OutBack } }

      Rectangle {
        x: parent.width - Style.space(7)
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(12)
        height: width
        radius: Style.space(3)
        rotation: 45
        color: parent.color
      }
      Text {
        id: said
        textFormat: Text.PlainText
        x: Style.space(17)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, corner.width - avatar.width - Style.space(48))
        text: root.line
        color: "#f6e9ef"
        font.family: root.voice
        font.pixelSize: Style.space(15)
        wrapMode: Text.WordWrap
      }
    }

    DivaAvatar {
      id: avatar
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      width: Style.space(96)
      height: width
      mood: root.mood
      animate: root.lively
      lookX: root.hovered ? pointer.lookX : root.lookX
      lookY: root.hovered ? pointer.lookY : root.lookY
      near: root.hovered ? 0.8 : 0
      opacity: root.hovered || root.line !== "" || root.loved ? 1 : 0.88
      Behavior on opacity { NumberAnimation { duration: 200 } }
      onClicked: root.clicked()

      HoverHandler {
        id: pointer
        readonly property real lookX: Math.max(-1, Math.min(1, (point.position.x - avatar.width / 2) / (avatar.width / 2)))
        readonly property real lookY: Math.max(-1, Math.min(1, (point.position.y - avatar.height / 2) / (avatar.height / 2)))
        onHoveredChanged: {
          root.hovered = hovered
          if (hovered && root.line === "") root.say("Clique-moi, j'ouvre mon menu.", 3500)
        }
      }
    }
  }
}
