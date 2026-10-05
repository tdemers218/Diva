import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import "core/Actions.js" as Actions
import "core/Smart.js" as Smart
import "core/Icons.js" as Icons

// Diva's menu: a frosted-glass card where Diva herself is always present.
// She greets, listens, follows the pointer, and speaks in the bubble beside
// her. Below her: a line to type in, then either her favourites and a
// control centre, the results for what was typed, or a conversation.
// Everything shown is French. Requests are understood locally first
// (core/Actions.js, core/Smart.js) and run as fixed argv; questions go to
// the optional assistant (bin/diva-ai).
Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  readonly property string home: Quickshell.env("HOME")
  readonly property string pluginId: (manifest && manifest.id) || "io.github.tdemers218.diva"
  readonly property string pluginDir: decodeURIComponent(String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")).replace(/\/$/, "")

  property bool opened: false
  // 0 closed .. 1 open; everything that fades or slides follows it.
  property real reveal: opened ? 1 : 0
  // "home", "settings" or "plugins".
  property string page: "home"
  // "movie" while the choice of where to watch is showing; "" otherwise.
  property string group: ""
  property string query: ""
  property int selected: 0
  property var tiles: []
  // The same tiles arranged for display: [{ id, title, tiles }] (Smart.layout).
  property var sections: []
  property var apps: []
  property string answer: ""
  property string reply: ""
  // "<kind>:<id>" of the tile waiting for a second click.
  property string pendingConfirm: ""
  property bool stagger: false

  // Assistant.
  property bool thinking: false
  property string asked: ""
  property int dots: 1
  // "ask" for a request from the menu, "test" for the settings page's button.
  property string aiMode: "ask"
  // What bin/diva-ai --status reports: the provider in use with its
  // { cli, loggedIn, plan }, and the same plus `models` and `model` for each
  // of claude, chatgpt and anthropic.
  property var aiStatus: ({ provider: "claude", cli: true, loggedIn: false, plan: "", claude: ({}), chatgpt: ({}), anthropic: ({}) })
  property bool keyStored: false
  property string settingsStatus: ""
  // The conversation with her assistant: [{ who: "me" | "diva", text }].
  property var chat: []

  // ~/.config/diva/config.json; see docs/architecture.md for the keys.
  property var config: ({})
  // ~/.local/state/diva/learned.json: requests the assistant resolved once.
  property var learned: []
  // Every entry of Omarchy's own menu, for maintenance (Smart.parseCommands).
  property var commands: []
  // Her folders are named by her locale (Téléchargements), so ask XDG.
  property var dirs: ({ HOME: home, DOWNLOAD: home + "/Downloads", PICTURES: home + "/Pictures", DOCUMENTS: home + "/Documents" })
  // Open windows, read when the menu opens: [{ address, cls, title, workspace, icon }].
  property var windows: []
  // Omarchy's live key bindings, { description: keys }, for Diva's guide.
  property var bindings: ({})
  // What bin/diva-state reports, for the control centre.
  property var state: ({ volume: 0, muted: false, brightness: -1, wifi: false, network: "", bluetooth: false, battery: -1, charging: false })
  property var pendingControl: null

  // Diva's presence: where the pointer is relative to her, and her mood.
  property real lookX: 0
  property real lookY: 0
  property real near: 0
  property double lastActivity: 0
  property double lastPointer: 0
  property bool sleepy: false
  // A mood that takes over for a moment: "love", "sad" or "".
  property string flash: ""
  property int pokes: 0

  // Signed in is enough: the assistant is on unless she switched it off.
  readonly property bool aiReady: aiStatus.cli === true && aiStatus.loggedIn === true
  readonly property bool aiEnabled: aiReady && !(config.ai && config.ai.enabled === false)
  readonly property bool animate: config.animations !== false
  readonly property bool showCommands: config.advancedSearch !== false
  readonly property bool chatting: page === "home" && chat.length > 0
  readonly property bool atHome: page === "home" && !chatting && group === "" && query === ""
  readonly property string keyPath: {
    var custom = String((config.ai && config.ai.keyFile) || "")
    return custom ? custom.replace(/^~/, home) : home + "/.config/diva/api-key"
  }
  function ms(n) { return animate ? n : 0 }

  // Frosted glass over plum, in the manner of recent macOS: translucent
  // surfaces, hairline highlights, large soft corners.
  readonly property color ink: "#f6e9ef"
  readonly property color soft: "#cfb2c2"
  readonly property color rose: "#eaa3c0"
  readonly property color deepRose: "#b8738f"
  readonly property color glass: Qt.rgba(0.17, 0.11, 0.16, 0.6)
  readonly property color tileColor: Qt.rgba(1, 1, 1, 0.075)
  readonly property color tileSelected: Qt.rgba(0.92, 0.64, 0.75, 0.3)
  readonly property color hairline: Qt.rgba(1, 1, 1, 0.13)
  readonly property color field: Qt.rgba(0, 0, 0, 0.26)
  // A clean sans for the interface; Diva's own voice keeps her rounded hand.
  readonly property string fontFamily: Qt.fontFamilies().indexOf("Adwaita Sans") >= 0 ? "Adwaita Sans" : Style.font.family
  readonly property string voiceFamily: fredoka.status === FontLoader.Ready ? fredoka.font.family : fontFamily
  // Icons are glyphs of the Nerd Font Omarchy sets as its interface font.
  readonly property string iconFamily: Style.font.family

  readonly property int cardWidth: Math.min(Style.space(page === "plugins" ? 1060 : 780), panel.width - Style.space(56))
  readonly property int cardPadding: Style.space(26)

  readonly property string mood: {
    if (thinking) return "thinking"
    if (flash) return flash
    if (reply !== "" || answer !== "") return "happy"
    if (sleepy) return "sleepy"
    if (near > 0.5) return "shy"
    if (query !== "" && (/\?/.test(query) || (tiles.length > 0 && tiles[0].kind === "ai"))) return "curious"
    return "idle"
  }
  readonly property string greeting: {
    var name = String(config.name || "").trim()
    var hour = new Date().getHours()
    var hello = hour < 5 ? "Tu ne dors pas encore" : hour < 12 ? "Bonjour" : hour < 18 ? "Coucou" : "Bonsoir"
    return hello + (name ? " " + name : "") + (hour < 5 ? " ?" : " !")
  }
  // What Diva is saying right now.
  readonly property string hint: {
    if (thinking) return "Je réfléchis" + "...".slice(0, dots)
    if (reply) return reply
    if (answer) return answer
    if (sleepy) return "Zzz…"
    if (page === "settings") return "Mes réglages. Dis-moi ce qu'on change."
    if (page === "plugins") return "Les extensions d'Omarchy. Regarde, il y en a pour tout."
    if (chatting) return "Je t'écoute. Échap pour arrêter de discuter."
    if (group === "movie" && !query) return "Où veux-tu regarder ? Échap pour revenir."
    if (group === "windows" && !query)
      return windows.length ? "Tes fenêtres ouvertes, puis ce que je peux faire avec celle où tu étais."
                            : "Aucune fenêtre ouverte pour l'instant."
    if (query && tiles.length === 0) return "Dis-m'en un peu plus."
    if (query && tiles[0].kind === "ai") return "Bonne question. Appuie sur Entrée, je te réponds."
    if (query) return "Appuie sur Entrée ou clique."
    // She mentions a low battery before being asked.
    if (state.battery >= 0 && state.battery <= 20 && !state.charging)
      return greeting + " Au fait, il ne te reste que " + state.battery + " % de batterie, pense à la brancher."
    return greeting + " Qu'est-ce que tu veux faire ?"
  }

  Behavior on reveal { NumberAnimation { duration: root.ms(root.opened ? 240 : 140); easing.type: Easing.OutCubic } }

  // ------------------------------------------------------------ lifecycle

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }
    root.cancelThinking()
    closeTimer.stop()
    root.reply = ""
    root.flash = ""
    root.pendingConfirm = ""
    root.page = String(payload.page || "home")
    root.settingsStatus = ""
    root.group = ""
    root.chat = []
    root.sleepy = false
    root.lastActivity = Date.now()
    root.apps = root.appList()
    root.stagger = true
    staggerTimer.restart()
    root.opened = true
    input.text = String(payload.query || "")
    root.refresh()
    root.control("", "")
    root.checkAi()
    if (!windowsProc.running) windowsProc.running = true
    avatar.hello()
    Qt.callLater(function() { input.forceActiveFocus() })
  }

  function close() {
    root.cancelThinking()
    root.opened = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId)
  }

  function appList() {
    var values = DesktopEntries.applications.values || []
    var out = []
    for (var i = 0; i < values.length; i++) {
      var e = values[i]
      if (!e || e.noDisplay || !e.name) continue
      out.push({ id: String(e.id), name: String(e.name), icon: String(e.icon || "") })
    }
    return out
  }

  function refresh() {
    root.query = input.text
    var found = Smart.resolve(root.query, { apps: root.apps, learned: root.learned, aiEnabled: root.aiEnabled, now: new Date(),
                                            commands: root.commands, showCommands: root.showCommands, group: root.group,
                                            state: root.state, windows: root.windows, bindings: root.bindings })
    if (root.query === "" && root.group === "") {
      // Home: her favourites, shown by HomePanel.
      root.sections = []
      root.tiles = found.tiles
      root.selected = 0
    } else {
      // Results: sections, each with its own kind of card; Enter runs the best.
      var arranged = Smart.layout(found.tiles)
      results.cards = ({})
      root.sections = arranged.sections
      root.tiles = arranged.flat
      root.selected = arranged.best
    }
    root.answer = found.answer
    root.pendingConfirm = ""
  }

  function move(delta) {
    if (root.tiles.length === 0) return
    root.selected = Math.max(0, Math.min(root.tiles.length - 1, root.selected + delta))
    root.cancelConfirm()
  }

  // Up and down go to the card above or below, wherever its section puts it.
  function moveVertical(direction) {
    if (root.atHome || root.tiles.length === 0) return
    root.selected = results.vertical(direction)
    root.cancelConfirm()
  }

  function cancelConfirm() {
    if (!root.pendingConfirm) return
    root.pendingConfirm = ""
    root.reply = ""
  }

  // Things that cannot be undone, and installs, ask once; the second click
  // goes through.
  function needsConfirm(tile) {
    var question = tile.confirm || ""
    if (tile.kind === "action") {
      var action = Actions.byId(tile.id)
      question = action && action.confirm ? action.confirm : ""
    }
    var key = tile.kind + ":" + tile.id
    if (!question || root.pendingConfirm === key) return false
    root.pendingConfirm = key
    root.reply = question
    replyTimer.stop()
    return true
  }

  function openGroup(name) {
    root.group = name
    input.text = ""
    root.reply = ""
    root.refresh()
  }

  function activate(index) {
    if (root.tiles[index]) {
      root.selected = index
      root.activateTile(root.tiles[index])
    }
  }

  function activateTile(tile) {
    if (!tile || root.thinking) return
    root.touched()
    if (tile.kind === "ai") { root.askAi(root.query); return }
    if (tile.kind === "setting" && tile.page) { root.page = tile.page; return }
    if (tile.kind === "help") {
      // A tip is said, not run; the full list of shortcuts opens Omarchy's viewer.
      var viewer = Smart.argv(tile, root.config, root.dirs, root.pluginDir)
      if (viewer) { root.runAndClose(viewer); return }
      root.reply = tile.text
      replyTimer.stop()
      return
    }
    if (tile.kind === "action" && Actions.byId(tile.id).effect.type === "group") {
      root.openGroup(Actions.byId(tile.id).effect.group)
      return
    }
    if (root.needsConfirm(tile)) return
    root.run(tile, "")
  }

  // Run a tile. `said` is what the assistant answered, when she chose it.
  function run(tile, said) {
    if (tile.kind === "action" && Actions.byId(tile.id).effect.type === "group") {
      // Her assistant chose "films": show the choice instead of closing.
      root.chat = []
      root.openGroup(Actions.byId(tile.id).effect.group)
      root.reply = said
      return
    }
    var argv = Smart.argv(tile, root.config, root.dirs, root.pluginDir)
    if (!argv) return
    root.pendingConfirm = ""
    Quickshell.execDetached(argv)
    var result = Smart.outcome(tile)
    root.reply = said || result.reply
    if (result.stay) {
      if (!said) replyTimer.restart()
      stateTimer.restart()
    } else if (said) {
      // Leave her answer on screen for a moment before making way.
      closeTimer.restart()
    } else {
      root.dismiss()
    }
  }

  function runAndClose(argv) {
    Quickshell.execDetached(argv)
    root.dismiss()
  }

  function runQuiet(argv, said) {
    Quickshell.execDetached(argv)
    root.reply = said
    replyTimer.restart()
  }

  // ------------------------------------------------------- control centre

  // Ask bin/diva-state to change one thing (or nothing) and report back.
  // Slider drags arrive faster than the helper answers: keep only the latest.
  function control(what, value) {
    if (stateProc.running) {
      if (what) root.pendingControl = [what, value]
      return
    }
    root.pendingControl = null
    stateProc.command = what ? [root.pluginDir + "/bin/diva-state", what, String(value)] : [root.pluginDir + "/bin/diva-state"]
    stateProc.running = true
    if (what) root.touched()
  }

  // ------------------------------------------------------------- presence

  // Anything she does wakes Diva up.
  function touched() {
    root.lastActivity = Date.now()
    if (root.sleepy) {
      root.sleepy = false
      root.say("Oh ! J'étais dans la lune.")
    }
  }

  function say(text) {
    root.reply = text
    replyTimer.restart()
  }

  // The pointer moved, in the panel's coordinates.
  function pointerAt(x, y) {
    var centre = avatar.mapToItem(tracker, avatar.width / 2, avatar.height / 2)
    var dx = x - centre.x, dy = y - centre.y
    root.lookX = Math.max(-1, Math.min(1, dx / Style.space(260)))
    root.lookY = Math.max(-1, Math.min(1, dy / Style.space(200)))
    root.near = Math.max(0, Math.min(1, 1 - (Math.sqrt(dx * dx + dy * dy) - avatar.width / 2) / Style.space(110)))
    root.lastPointer = Date.now()
    root.touched()
  }

  readonly property var quips: [
    "Hi hi, ça chatouille !", "Oui ? Je suis là.", "Tu veux jouer ?", "Encore ! Encore !",
    "Toi, tu as envie de discuter.", "Je t'écoute, toujours.", "Tu es de bonne humeur, ça se voit.",
    "Attention, je vais rougir.", "On fait quoi aujourd'hui ?"
  ]
  function poked() {
    root.touched()
    root.pokes += 1
    pokeReset.restart()
    avatar.poke()
    root.flash = "love"
    flashTimer.restart()
    root.say(root.pokes >= 5 ? "Stop, stop, j'ai la tête qui tourne !" : root.quips[Math.floor(Math.random() * root.quips.length)])
  }

  // ------------------------------------------------------------ assistant

  function askAi(text) {
    text = String(text || "").trim()
    if (!text || root.thinking) return
    root.aiMode = "ask"
    root.asked = text
    root.reply = ""
    var before = root.chat
    root.chat = before.concat([{ who: "me", text: text }])
    input.text = ""
    root.query = ""
    root.thinking = true
    aiProcess.command = [root.pluginDir + "/bin/diva-ai", JSON.stringify({
      request: text,
      history: before.slice(-8),
      guide: Smart.guideLines(root.bindings),
      actions: Actions.ACTIONS.map(function(a) { return { id: a.id, title: a.title } }),
      apps: root.apps.slice(0, 80).map(function(a) { return a.name })
    })]
    aiProcess.running = true
    Qt.callLater(function() { talk.positionViewAtEnd() })
  }

  function cancelThinking() {
    if (!root.thinking) return
    root.thinking = false
    aiProcess.running = false
  }

  function aiError(code) {
    if (code === "login") return "Je ne suis pas encore connectée à ton compte Claude. Ouvre mes réglages."
    if (code === "cli") return "Il me manque Claude Code sur cet ordinateur. Ouvre mes réglages."
    if (code === "key") return "Il me manque une clé. Ouvre mes réglages."
    if (code === "network") return "Je n'arrive pas à me connecter à Internet."
    if (code === "busy") return "Il y a trop de monde, réessaie dans un instant."
    if (code === "refused") return "Ça, je ne peux pas t'aider."
    return "Oups, je n'ai pas réussi cette fois."
  }

  function aiDone(text) {
    if (!root.thinking) return
    root.thinking = false
    var r = null
    try { r = JSON.parse(String(text).trim()) } catch (e) { r = null }
    if (root.aiMode === "test") {
      root.settingsStatus = r && r.ok === true ? "Ça marche : « " + String(r.reply || "").trim() + " »" : root.aiError(r ? r.error : "")
      return
    }
    if (!r || r.ok !== true) {
      root.reply = root.aiError(r ? r.error : "")
      root.flash = "sad"
      flashTimer.restart()
      return
    }
    var said = String(r.reply || "").trim() || "Je ne sais pas trop."
    root.chat = root.chat.concat([{ who: "diva", text: said }])
    root.reply = said
    Qt.callLater(function() { talk.positionViewAtEnd() })
    var tile = Smart.intentTile(r.intent, root.apps)
    if (!tile) return
    root.learn(root.asked, tile)
    if (root.needsConfirm(tile)) {
      // Show what is waiting for her second click.
      root.chat = []
      var waiting = Smart.layout([tile])
      results.cards = ({})
      root.sections = waiting.sections
      root.tiles = waiting.flat
      root.selected = 0
      return
    }
    root.run(tile, said)
  }

  // Remember what a request turned out to mean, so next time it is answered
  // here without the assistant.
  function learn(text, tile) {
    var key = Smart.learnedKey(text)
    var intent = Smart.tileIntent(tile)
    if (!key || !intent) return
    var next = root.learned.filter(function(l) { return l.key !== key })
    next.push({ key: key, request: text, title: tile.title, intent: intent, at: new Date().toISOString() })
    root.learned = next.slice(-200)
    learnedFile.setText(JSON.stringify(root.learned, null, 2) + "\n")
  }

  // ------------------------------------------------------------- settings

  // Set one value in config.json, e.g. setSetting(["ai", "enabled"], true).
  function setSetting(path, value) {
    var next = JSON.parse(JSON.stringify(root.config || {}))
    var at = next
    for (var i = 0; i < path.length - 1; i++) {
      if (!at[path[i]] || typeof at[path[i]] !== "object") at[path[i]] = {}
      at = at[path[i]]
    }
    at[path[path.length - 1]] = value
    root.config = next
    configFile.setText(JSON.stringify(next, null, 2) + "\n")
    if (root.page === "home") root.refresh()
  }

  // The key is piped to a file only she can read; it never appears in a
  // command line or in config.json.
  function saveKey(key) {
    key = String(key || "").replace(/\s+/g, "")
    if (!key || keyWriter.running) return
    keyWriter.command = ["sh", "-c", "umask 077; mkdir -p \"$(dirname \"$1\")\"; head -n1 > \"$1\"", "sh", root.keyPath]
    keyWriter.running = true
    keyWriter.write(key + "\n")
    root.settingsStatus = "Clé enregistrée. Appuie sur « Tester » pour vérifier."
  }

  function testAi() {
    if (root.thinking) return
    root.aiMode = "test"
    root.settingsStatus = "Je vérifie…"
    root.thinking = true
    aiProcess.command = [root.pluginDir + "/bin/diva-ai", JSON.stringify({ request: "Dis-moi bonjour !", actions: [], apps: [] })]
    aiProcess.running = true
  }

  // Sign in to Claude in the browser, from a terminal she can watch.
  function login() {
    Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", root.pluginDir + "/bin/diva-ai", "--login"])
    root.dismiss()
  }

  function setProvider(provider) {
    root.setSetting(["ai", "provider"], provider)
    root.settingsStatus = ""
    recheck.restart()
  }

  function setModel(provider, id) {
    root.setSetting(["ai", "models", provider], id)
    root.settingsStatus = ""
    recheck.restart()
  }

  function checkAi() {
    if (!statusCheck.running) statusCheck.running = true
    if (!keyCheck.running) keyCheck.running = true
  }

  function forgetLearned() {
    root.learned = []
    learnedFile.setText("[]\n")
  }

  function goHome() {
    root.page = "home"
    root.settingsStatus = ""
    root.refresh()
    Qt.callLater(function() { input.forceActiveFocus() })
  }

  function loadCommands() {
    root.commands = Smart.parseCommands([menuDefaults.text(), menuExtensions.text()])
  }

  function iconSource(icon) {
    if (!icon) return Quickshell.iconPath("application-x-executable", true)
    if (icon.charAt(0) === "/") return Util.fileUrl(icon)
    var themed = Quickshell.iconPath(icon, true)
    return themed.length > 0 ? themed : Quickshell.iconPath("application-x-executable", true)
  }

  // For checks, through `omarchy-shell shell call <id> <method> <arg>`.
  function ask(text) {
    if (!root.opened) root.apps = root.appList()
    input.text = String(text || "")
    root.refresh()
    return "ok"
  }
  function activateIndex(index) {
    root.activate(parseInt(index) || 0)
    return "ok"
  }
  function poke(arg) {
    root.poked()
    return "ok"
  }
  function inspect(arg) {
    return JSON.stringify({ opened: root.opened, page: root.page, group: root.group, query: root.query, hint: root.hint,
      selected: root.selected, mood: root.mood, lookX: root.lookX, lookY: root.lookY, near: root.near, sleepy: root.sleepy,
      font: root.fontFamily, voice: root.voiceFamily, dirs: root.dirs, config: root.config, state: root.state,
      pendingConfirm: root.pendingConfirm, thinking: root.thinking, aiEnabled: root.aiEnabled, aiStatus: root.aiStatus,
      chat: root.chat, learned: root.learned.length, windows: root.windows.length, bindings: Object.keys(root.bindings).length, commands: root.commands.length, keyStored: root.keyStored,
      settingsStatus: root.settingsStatus,
      sections: root.sections.map(function(x) { return x.id + "(" + x.tiles.length + ")" }),
      tiles: root.tiles.map(function(t) { return t.kind + ":" + t.id + ":" + t.title }) })
  }

  onPageChanged: if (page === "settings") root.checkAi()

  FontLoader {
    id: fredoka
    source: Qt.resolvedUrl("fonts/Fredoka.ttf")
  }

  Timer { id: replyTimer; interval: 3200; onTriggered: root.reply = "" }
  Timer { id: closeTimer; interval: 1800; onTriggered: root.dismiss() }
  Timer { id: staggerTimer; interval: 600; onTriggered: root.stagger = false }
  Timer { id: flashTimer; interval: 1800; onTriggered: root.flash = "" }
  Timer { id: pokeReset; interval: 2500; onTriggered: root.pokes = 0 }
  // After a setting is written, ask the helper again who is signed in.
  Timer { id: recheck; interval: 300; onTriggered: root.checkAi() }
  Timer { id: stateTimer; interval: 350; onTriggered: root.control("", "") }
  Timer { interval: 350; repeat: true; running: root.thinking; onTriggered: root.dots = root.dots % 3 + 1 }
  // While she is open: refresh the control centre, doze off when nothing
  // happens, and glance around when the pointer is still.
  Timer {
    interval: 2500
    repeat: true
    running: root.opened
    onTriggered: {
      if (root.atHome) root.control("", "")
      var now = Date.now()
      if (!root.sleepy && !root.thinking && now - root.lastActivity > 28000) root.sleepy = true
      if (now - root.lastPointer > 4000 && !root.sleepy) {
        root.near = 0
        root.lookX = root.query ? 0.45 : (Math.random() * 1.4 - 0.7)
        root.lookY = root.query ? 0.7 : (Math.random() * 0.8 - 0.3)
        glanceBack.restart()
      }
    }
  }
  Timer { id: glanceBack; interval: 1100; onTriggered: if (Date.now() - root.lastPointer > 4000) { root.lookX = 0; root.lookY = 0 } }

  FileView {
    id: menuDefaults
    path: root.omarchyPath + "/default/omarchy/omarchy-menu.jsonc"
    printErrors: false
    onLoaded: root.loadCommands()
  }
  FileView {
    id: menuExtensions
    path: root.home + "/.config/omarchy/extensions/omarchy-menu.jsonc"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loadCommands()
  }

  FileView {
    id: configFile
    path: root.home + "/.config/diva/config.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.config = JSON.parse(text()) || ({}) } catch (e) { root.config = ({}) }
    }
    onLoadFailed: root.config = ({})
  }

  FileView {
    id: learnedFile
    path: root.home + "/.local/state/diva/learned.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var list = []
      try { list = JSON.parse(text()) } catch (e) { list = [] }
      root.learned = Array.isArray(list) ? list : []
    }
    onLoadFailed: root.learned = []
  }

  Process {
    id: aiProcess
    stdout: StdioCollector { onStreamFinished: root.aiDone(text) }
  }
  Process {
    id: statusCheck
    command: [root.pluginDir + "/bin/diva-ai", "--status"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.aiStatus = JSON.parse(String(text).trim()) } catch (e) {}
      }
    }
  }
  Process {
    id: keyCheck
    command: ["test", "-s", root.keyPath]
    running: true
    onExited: function(code) { root.keyStored = code === 0 }
  }
  Process {
    id: keyWriter
    stdinEnabled: true
    onExited: root.checkAi()
  }
  // What is open right now. Hyprland's own list; an app's icon is looked up
  // among the installed applications by its window class.
  Process {
    id: windowsProc
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        var list = []
        try { list = JSON.parse(String(text)) } catch (e) { list = [] }
        var out = []
        for (var i = 0; i < list.length; i++) {
          var c = list[i]
          if (!c || !c.mapped || c.hidden || !c.workspace || c.workspace.id < 1) continue
          var cls = String(c.class || c.initialClass || "")
          var icon = ""
          for (var a = 0; a < root.apps.length && !icon; a++)
            if (root.apps[a].id.toLowerCase() === cls.toLowerCase() || root.apps[a].icon.toLowerCase() === cls.toLowerCase())
              icon = root.apps[a].icon
          out.push({ address: String(c.address), cls: cls, title: String(c.title || ""), workspace: c.workspace.id, icon: icon })
        }
        root.windows = out
        if (root.opened && (root.group === "windows" || root.query !== "")) root.refresh()
      }
    }
  }
  Process {
    running: true
    command: ["omarchy-menu-keybindings", "--print"]
    stdout: StdioCollector { onStreamFinished: root.bindings = Smart.parseBindings(text) }
  }
  Process {
    id: stateProc
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.state = JSON.parse(String(text).trim()) } catch (e) {}
        if (root.pendingControl) root.control(root.pendingControl[0], root.pendingControl[1])
      }
    }
  }
  Process {
    running: true
    command: ["sh", "-c", "for d in DOWNLOAD PICTURES DOCUMENTS; do printf '%s=%s\\n' \"$d\" \"$(xdg-user-dir \"$d\")\"; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        var next = ({ HOME: root.home, DOWNLOAD: root.dirs.DOWNLOAD, PICTURES: root.dirs.PICTURES, DOCUMENTS: root.dirs.DOCUMENTS })
        var lines = String(text).split("\n")
        for (var i = 0; i < lines.length; i++) {
          var at = lines[i].indexOf("=")
          if (at > 0 && lines[i].charAt(at + 1) === "/") next[lines[i].slice(0, at)] = lines[i].slice(at + 1)
        }
        root.dirs = next
      }
    }
  }

  PanelWindow {
    id: panel
    // Stays up while the closing fade plays.
    visible: root.opened || root.reveal > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "diva-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // A faint veil; the frost itself is the compositor's blur behind the card.
    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0.05, 0.03, 0.05, 0.22)
      opacity: root.reveal
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    // Watches the pointer everywhere, for Diva's eyes.
    Item {
      id: tracker
      anchors.fill: parent
      HoverHandler {
        onPointChanged: if (root.opened) root.pointerAt(point.position.x, point.position.y)
      }

      Item {
        id: stage
        width: root.cardWidth
        height: card.height
        anchors.centerIn: parent
        opacity: root.reveal
        scale: 0.95 + 0.05 * root.reveal
        transform: Translate { y: (1 - root.reveal) * Style.space(18) }
        Behavior on width { NumberAnimation { duration: root.ms(220); easing.type: Easing.OutCubic } }

        Rectangle {
          id: card
          width: parent.width
          height: root.page === "plugins" ? panel.height - Style.space(72)
                                          : Math.min(content.implicitHeight + root.cardPadding * 2, panel.height - Style.space(56))
          radius: Style.space(34)
          color: root.glass
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.2)
          clip: true
          Behavior on height { NumberAnimation { duration: root.ms(200); easing.type: Easing.OutCubic } }

          // Light catching the top of the glass.
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
              GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.11) }
              GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.02) }
              GradientStop { position: 1; color: Qt.rgba(0.9, 0.55, 0.7, 0.05) }
            }
          }

          MouseArea { anchors.fill: parent; onClicked: if (root.page === "home") input.forceActiveFocus() }

          // The one discreet door to settings, extensions and Omarchy's tools.
          DivaButton {
            z: 1
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: root.cardPadding
            anchors.rightMargin: root.cardPadding
            diva: root
            glyph: root.page === "home" ? "cog" : "arrow-left"
            text: root.page === "home" ? "" : root.page === "plugins" ? "Réglages" : "Retour"
            onClicked: {
              if (root.page === "home") root.page = "settings"
              else if (root.page === "plugins") root.page = "settings"
              else root.goHome()
            }
          }

          Column {
            id: content
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: Style.space(16)

            // Diva, always here, and what she is saying.
            Row {
              id: header
              width: parent.width
              spacing: Style.space(10)

              DivaAvatar {
                id: avatar
                width: Style.space(92)
                height: width
                mood: root.mood
                animate: root.animate && root.opened
                lookX: root.lookX
                lookY: root.lookY
                near: root.near
                onClicked: root.poked()
              }

              Item {
                width: parent.width - avatar.width - parent.spacing - Style.space(110)
                height: avatar.height

                Rectangle {
                  id: bubble
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(8)
                  width: Math.min(parent.width - Style.space(8), said.implicitWidth + Style.space(36))
                  height: Math.max(Style.space(46), said.implicitHeight + Style.space(24))
                  radius: Style.space(22)
                  color: Qt.rgba(1, 1, 1, 0.11)
                  border.width: 1
                  border.color: root.hairline
                  Behavior on width { NumberAnimation { duration: root.ms(180); easing.type: Easing.OutCubic } }
                  Behavior on height { NumberAnimation { duration: root.ms(180); easing.type: Easing.OutCubic } }

                  // The bubble's tail, toward her.
                  Rectangle {
                    x: -Style.space(5)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.space(12)
                    height: width
                    radius: Style.space(3)
                    rotation: 45
                    color: Qt.rgba(1, 1, 1, 0.11)
                  }

                  SequentialAnimation {
                    running: root.thinking && root.animate
                    loops: Animation.Infinite
                    onStopped: bubble.opacity = 1
                    NumberAnimation { target: bubble; property: "opacity"; to: 0.6; duration: 500; easing.type: Easing.InOutSine }
                    NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: 500; easing.type: Easing.InOutSine }
                  }

                  Text {
                    id: said
                    textFormat: Text.PlainText
                    x: Style.space(18)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, bubble.parent.width - Style.space(44))
                    text: root.hint
                    color: root.ink
                    font.family: root.voiceFamily
                    font.pixelSize: Style.space(16)
                    wrapMode: Text.WordWrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                    // Each new sentence fades in.
                    onTextChanged: if (!root.thinking) sayIn.restart()
                    NumberAnimation { id: sayIn; target: said; property: "opacity"; from: 0.2; to: 1; duration: root.ms(220) }
                  }
                }
              }
            }

            Rectangle {
              id: searchField
              visible: root.page === "home"
              width: parent.width
              height: Style.space(52)
              radius: height / 2
              color: root.field
              border.width: input.activeFocus ? Style.space(1.5) : 1
              border.color: input.activeFocus ? root.rose : root.hairline
              Behavior on border.color { ColorAnimation { duration: root.ms(150) } }

              Text {
                id: glass
                anchors.left: parent.left
                anchors.leftMargin: Style.space(19)
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.glyph(root.chatting ? "creation" : "magnify")
                color: root.chatting ? root.rose : root.soft
                font.family: root.iconFamily
                font.pixelSize: Style.space(18)
              }

              TextInput {
                id: input
                anchors.left: glass.right
                anchors.leftMargin: Style.space(11)
                anchors.right: parent.right
                anchors.rightMargin: Style.space(20)
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                focus: true
                color: root.ink
                selectionColor: root.deepRose
                selectedTextColor: root.ink
                font.family: root.fontFamily
                font.pixelSize: Style.space(17)
                onTextEdited: {
                  root.touched()
                  avatar.typed()
                  closeTimer.stop()
                  if (root.chatting) { root.query = text; return }
                  root.cancelThinking()
                  root.reply = ""
                  root.refresh()
                }

                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Escape) {
                    if (root.thinking) root.cancelThinking()
                    else if (root.pendingConfirm) root.cancelConfirm()
                    else if (input.text) { input.text = ""; root.reply = ""; root.refresh() }
                    else if (root.chatting) { root.chat = []; root.reply = ""; root.refresh() }
                    else if (root.group) root.openGroup("")
                    else root.dismiss()
                  } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.chatting) root.askAi(input.text)
                    else root.activate(root.selected)
                  } else if (root.chatting) {
                    return
                  } else if (event.key === Qt.Key_Down) {
                    root.moveVertical(1)
                  } else if (event.key === Qt.Key_Up) {
                    root.moveVertical(-1)
                  } else if (event.key === Qt.Key_Tab || (event.key === Qt.Key_Right && !input.text)) {
                    root.move(1)
                  } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Left && !input.text)) {
                    root.move(-1)
                  } else {
                    return
                  }
                  event.accepted = true
                }

                Text {
                  anchors.fill: parent
                  verticalAlignment: Text.AlignVCenter
                  visible: !input.text
                  text: root.chatting ? "Réponds-moi…"
                      : root.aiEnabled ? "Demande-moi ce que tu veux, avec tes mots…"
                                       : "Écris-moi ici… par exemple « regarder un film »"
                  color: root.soft
                  opacity: 0.65
                  elide: Text.ElideRight
                  font: input.font
                }
              }
            }

            // Before she types: favourites and the control centre.
            HomePanel {
              visible: root.atHome
              width: parent.width
              diva: root
            }

            // The conversation with her assistant.
            ListView {
              id: talk
              visible: root.chatting
              width: parent.width
              height: Math.min(contentHeight, Style.space(300))
              clip: true
              spacing: Style.space(8)
              boundsBehavior: Flickable.StopAtBounds
              model: root.chat
              // Each line of the conversation rises into place.
              add: Transition {
                ParallelAnimation {
                  NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.ms(220) }
                  NumberAnimation { property: "y"; from: talk.contentHeight; duration: root.ms(260); easing.type: Easing.OutCubic }
                }
              }
              delegate: Item {
                id: line
                required property var modelData
                readonly property bool mine: modelData.who === "me"
                width: talk.width
                height: words.height
                Rectangle {
                  id: words
                  anchors.right: line.mine ? parent.right : undefined
                  anchors.left: line.mine ? undefined : parent.left
                  width: Math.min(talk.width * 0.78, spoken.implicitWidth + Style.space(30))
                  height: spoken.implicitHeight + Style.space(18)
                  radius: Style.space(18)
                  color: line.mine ? Qt.rgba(0.92, 0.64, 0.75, 0.32) : Qt.rgba(1, 1, 1, 0.1)
                  border.width: 1
                  border.color: root.hairline
                  Text {
                    id: spoken
                    textFormat: Text.PlainText
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, talk.width * 0.78 - Style.space(30))
                    text: line.modelData.text
                    color: root.ink
                    font.family: line.mine ? root.fontFamily : root.voiceFamily
                    font.pixelSize: Style.space(15)
                    wrapMode: Text.WordWrap
                  }
                }
              }
            }

            // What she typed, answered in sections of differently shaped cards.
            ResultsView {
              id: results
              diva: root
              visible: root.page === "home" && !root.atHome && !root.chatting && root.tiles.length > 0
              width: parent.width
              height: Math.max(0, Math.min(contentHeight,
                panel.height - Style.space(56) - root.cardPadding * 2 - header.height - searchField.height - content.spacing * 2))
              Behavior on height { NumberAnimation { duration: root.ms(160); easing.type: Easing.OutCubic } }
            }

            // Settings and extensions take the place of all that.
            Loader {
              id: pageLoader
              visible: root.page !== "home"
              active: visible
              width: parent.width
              height: Math.max(0, root.page === "plugins"
                ? card.height - root.cardPadding * 2 - header.height - content.spacing
                : Math.min(Style.space(430), panel.height - Style.space(56) - root.cardPadding * 2 - header.height - content.spacing))
              source: root.page === "plugins" ? "PluginsPage.qml" : root.page === "settings" ? "SettingsPage.qml" : ""
              onLoaded: { item.diva = root; pageIn.restart() }
              // Each page slides up into place.
              transform: Translate { id: pageShift }
              ParallelAnimation {
                id: pageIn
                NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: root.ms(220) }
                NumberAnimation { target: pageShift; property: "y"; from: Style.space(14); to: 0; duration: root.ms(260); easing.type: Easing.OutCubic }
              }
              Keys.onEscapePressed: root.page === "plugins" ? root.page = "settings" : root.goHome()
            }
          }
        }
      }
    }
  }
}
