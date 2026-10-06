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
  // The request the assistant is working on, across its steps:
  // { request, level: "daily" | "deep", escalated, repairs, attempts, inspect, reason }.
  property var task: null
  // What Diva is really doing right now: "", "inspect", "repair", "test".
  property string phase: ""
  // Her little terminal: the last steps of the task, one line each.
  property var steps: []
  // A shortcut waiting for its action to be verified before it is learned.
  property var pendingLearn: null
  // What the running action will say once it is checked.
  property var running: null
  readonly property bool deep: task !== null && task.level === "deep"
  readonly property bool busy: thinking || phase !== ""
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
  // Diva's themes, as the settings show them. Each is an Omarchy theme the
  // pack installs (theme/<id>), with its own colours and wallpapers.
  readonly property var themes: [
    { id: "diva", name: "Prune", mood: "Sombre, vieux rose", background: "#241a24", foreground: "#ecd9e3", accent: "#e39ab8" },
    { id: "diva-lavande", name: "Lavande", mood: "Nuit mauve", background: "#1d1a2e", foreground: "#e4def5", accent: "#b8a4ee" },
    { id: "diva-menthe", name: "Menthe", mood: "Bleu-vert et rose", background: "#14222a", foreground: "#dcefe9", accent: "#8fd6c4" },
    { id: "diva-peche", name: "Pêche", mood: "Chaud, cacao", background: "#2a1e1b", foreground: "#f4e3d7", accent: "#f2a889" },
    { id: "diva-creme", name: "Crème", mood: "Clair et doux", background: "#f6ece6", foreground: "#54404a", accent: "#b85c7e" },
    { id: "diva-minuit", name: "Minuit", mood: "Noir et rose vif", background: "#131016", foreground: "#f1e6f0", accent: "#ff6fae" }
  ]
  // The Omarchy theme in use (its folder name).
  property string theme: ""
  // What bin/diva-state reports, for the control centre.
  property var state: ({ volume: 0, muted: false, brightness: -1, wifi: false, network: "", bluetooth: false, battery: -1, charging: false,
                         minutes: -1, saving: 0 })
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
    if (deep && busy) return "focus"
    if (thinking || phase !== "") return "thinking"
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
    if (phase === "inspect") return "Je vérifie" + "...".slice(0, dots)
    if (phase === "repair") return "Je m'en occupe" + "...".slice(0, dots)
    if (phase === "test") return "Je teste" + "...".slice(0, dots)
    if (thinking) return (deep ? "Je mets mes lunettes et je regarde ça de près" : "Je réfléchis") + "...".slice(0, dots)
    if (reply) return reply
    if (answer) return answer
    if (sleepy) return "Zzz…"
    if (page === "network") return "Choisis ton réseau. Je reste ici pendant la connexion."
    if (page === "bluetooth") return "Retrouvons tes écouteurs ou un autre appareil."
    if (page === "audio") return "Le son et le micro, comme tu les veux."
    if (page === "appearance") return "Un peu de lumière, et un fond qui te plaît."
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
      return greeting + " Au fait, il ne te reste que " + state.battery + " % de batterie : j'économise, pense à la brancher."
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
    if (!tile || root.busy) return
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
    if (tile.kind === "action" && Actions.byId(tile.id).effect.type === "page") {
      root.chat = []; root.task = null; root.pendingLearn = null
      root.page = Actions.byId(tile.id).effect.page
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
  // The action goes through bin/diva-run, which reports whether it really
  // happened: Diva only says so, and only learns a shortcut, once it has.
  function run(tile, said) {
    if (tile.kind === "action" && Actions.byId(tile.id).effect.type === "page") {
      root.chat = []; root.task = null; root.pendingLearn = null
      root.page = Actions.byId(tile.id).effect.page
      return
    }
    if (tile.kind === "action" && Actions.byId(tile.id).effect.type === "group") {
      // Her assistant chose "films": show the choice instead of closing.
      root.chat = []
      root.task = null
      root.openGroup(Actions.byId(tile.id).effect.group)
      root.reply = said
      return
    }
    var argv = Smart.argv(tile, root.config, root.dirs, root.pluginDir)
    if (!argv) return
    root.pendingConfirm = ""
    var result = Smart.outcome(tile)
    if (runner.running) {
      // Something is still being checked: do this one without the check.
      Quickshell.execDetached(argv)
      root.reply = said || result.reply
      if (result.stay) replyTimer.restart(); else root.dismiss()
      return
    }
    root.running = { tile: tile, said: said, reply: result.reply, stay: result.stay }
    runner.command = [root.pluginDir + "/bin/diva-run", Smart.check(tile), "--"].concat(argv)
    runner.running = true
    if (result.stay) return
    if (said) {
      // Leave her answer on screen for a moment before making way.
      root.reply = said
      closeTimer.restart()
    } else {
      root.dismiss()
    }
  }

  // bin/diva-run has checked the action that was running.
  function ran(text) {
    var done = root.running
    root.running = null
    if (!done) return
    var r = null
    try { r = JSON.parse(String(text).trim()) } catch (e) { r = null }
    var ok = !r || r.ok !== false
    var verified = !!r && r.verified === true
    if (ok && verified && root.pendingLearn && root.pendingLearn.tile === done.tile)
      root.learn(root.pendingLearn.text, done.tile)
    root.pendingLearn = null
    if (ok) {
      if (done.stay) {
        root.reply = done.said || done.reply
        if (!done.said) replyTimer.restart()
        stateTimer.restart()
      }
      if (root.task) root.task = null
      return
    }
    // It did not happen. Say so, here if she can still see it, otherwise as
    // a notification; and let the assistant have another look, once.
    root.flash = "sad"
    flashTimer.restart()
    if (root.task && !root.task.escalated && root.aiEnabled) {
      closeTimer.stop()
      root.task.attempts.push({ tried: done.tile.title, ok: false, detail: r.detail || "" })
      root.escalate("« " + done.tile.title + " » n'a pas marché : " + (r.detail || "aucun effet constaté"))
      return
    }
    root.task = null
    if (root.opened) {
      closeTimer.stop()
      root.reply = "Hmm, « " + done.tile.title + " » n'a pas marché."
    } else {
      Quickshell.execDetached(["omarchy-notification-send", "Diva", "Je n'ai pas réussi : " + done.tile.title + "."])
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
    // A pointer shaken close to her is a caress.
    if (root.near > 0.15) petting.feed(x); else petting.forget()
  }

  readonly property var purrs: ["Mmh, encore.", "Hi hi, c'est doux.", "J'adore ça.", "Tu vas me faire ronronner.", "Encore un peu ?"]
  function petted() {
    root.touched()
    avatar.pet()
    root.flash = "love"
    flashTimer.restart()
    root.say(root.purrs[Math.floor(Math.random() * root.purrs.length)])
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

  // A new request for the assistant: it starts at her everyday level.
  function askAi(text) {
    text = String(text || "").trim()
    if (!text || root.busy) return
    root.aiMode = "ask"
    root.asked = text
    root.reply = ""
    root.steps = []
    root.task = { request: text, level: "daily", escalated: false, repairs: 0, attempts: [], inspect: null, reason: "",
                  history: root.chat.slice(-8) }
    root.chat = root.chat.concat([{ who: "me", text: text }])
    input.text = ""
    root.query = ""
    root.callModel()
    Qt.callLater(function() { talk.positionViewAtEnd() })
  }

  // Ask the model at the task's level, with everything known so far. The
  // troubleshooting skill travels with the request once a state was checked.
  function callModel() {
    var t = root.task
    if (!t) return
    var payload = {
      request: t.request,
      level: t.level,
      history: t.history,
      guide: Smart.guideLines(root.bindings),
      actions: Actions.ACTIONS.map(function(a) { return { id: a.id, title: a.title } }),
      apps: root.apps.slice(0, 80).map(function(a) { return a.name })
    }
    if (t.inspect || t.attempts.length || t.reason)
      payload.context = { inspect: t.inspect || {}, attempts: t.attempts, reason: t.reason }
    root.phase = ""
    root.thinking = true
    aiProcess.command = [root.pluginDir + "/bin/diva-ai", JSON.stringify(payload)]
    aiProcess.running = true
  }

  function step(text) {
    root.steps = root.steps.concat([text]).slice(-4)
  }

  // Hand the task to the stronger model, once, with what was tried so far.
  // Her glasses change the model and nothing else: the same checks apply.
  function escalate(reason) {
    var t = root.task
    if (!t || t.escalated) return false
    t.escalated = true
    t.level = "deep"
    t.reason = reason
    root.task = t
    root.taskChanged()
    root.step("lunettes : " + reason)
    root.callModel()
    return true
  }

  // Stop whatever she is doing.
  function stop() {
    root.thinking = false
    root.phase = ""
    aiProcess.running = false
    doctor.running = false
    root.task = null
    root.pendingLearn = null
    root.reply = "D'accord, j'arrête."
    replyTimer.restart()
  }

  function cancelThinking() {
    if (!root.busy) return
    root.thinking = false
    root.phase = ""
    aiProcess.running = false
    doctor.running = false
    root.task = null
  }

  function aiError(code) {
    if (code === "login") return "Je ne suis pas encore connectée à ton compte. Ouvre mes réglages."
    if (code === "cli") return "Il me manque l'outil de mon abonnement sur cet ordinateur. Ouvre mes réglages."
    if (code === "key") return "Il me manque une clé. Ouvre mes réglages."
    if (code === "network") return "Je n'arrive pas à me connecter à Internet."
    if (code === "busy") return "Il y a trop de monde, réessaie dans un instant."
    if (code === "refused") return "Ça, je ne peux pas t'aider."
    return "Oups, je n'ai pas réussi cette fois."
  }

  function answerInChat(said) {
    root.chat = root.chat.concat([{ who: "diva", text: said }])
    root.reply = said
    Qt.callLater(function() { talk.positionViewAtEnd() })
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
      root.task = null
      return
    }
    var t = root.task
    var said = String(r.reply || "").trim() || "Je ne sais pas trop."
    var intent = r.intent || ({})

    // The everyday model may ask for the glasses, with a reason; once.
    if (r.escalate && t && !t.escalated && root.escalate(String(r.reason || "la demande est délicate"))) return

    if (intent.type === "diagnose" && t && !t.inspect) {
      // She does not guess: look first, then ask again with what was found.
      root.answerInChat(said)
      root.phase = "inspect"
      root.step("vérification de l'ordinateur")
      doctor.todo = "inspect"
      doctor.command = [root.pluginDir + "/bin/diva-doctor", "inspect"]
      doctor.running = true
      return
    }
    if (intent.type === "repair" && t && t.inspect) {
      // Two repairs at most for one request.
      if (t.repairs >= 2) { root.giveUp(); return }
      t.repairs += 1
      t.pending = String(intent.id || "")
      t.said = said
      root.answerInChat(said)
      root.phase = "repair"
      root.step("réparation : " + t.pending)
      doctor.todo = "repair"
      doctor.command = [root.pluginDir + "/bin/diva-doctor", "repair", t.pending]
      doctor.running = true
      return
    }

    root.answerInChat(said)
    var tile = Smart.intentTile(intent, root.apps)
    if (!tile) { root.task = null; return }
    // Learned only once the action is seen to have worked (see `ran`).
    root.pendingLearn = { text: root.asked, tile: tile }
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

  // bin/diva-doctor finished a step of the task.
  function doctored(what, text) {
    var t = root.task
    if (!t) { root.phase = ""; return }
    var r = null
    try { r = JSON.parse(String(text).trim()) } catch (e) { r = null }
    if (what === "inspect") {
      t.inspect = r || ({ problems: ["je n'ai pas réussi à lire l'état de l'ordinateur"] })
      var found = (t.inspect.problems || []).length
      root.step(found ? found + " anomalie" + (found > 1 ? "s" : "") + " trouvée" + (found > 1 ? "s" : "") : "rien d'anormal trouvé")
      // Several things wrong at once is a job for the glasses.
      if (found >= 2 && !t.escalated) { root.phase = ""; root.escalate("plusieurs anomalies à la fois"); return }
      root.callModel()
    } else if (what === "repair") {
      if (!r || r.ok !== true) {
        t.attempts.push({ repair: t.pending, ok: false, detail: (r && (r.message || r.error)) || "la réparation n'a pas pu être lancée" })
        root.phase = ""
        root.giveUp()
        return
      }
      root.phase = "test"
      root.step("test du résultat")
      doctor.todo = "verify"
      doctor.command = [root.pluginDir + "/bin/diva-doctor", "verify", t.pending]
      doctor.running = true
    } else if (what === "verify") {
      var ok = !!r && r.ok === true
      t.attempts.push({ repair: t.pending, ok: ok })
      root.phase = ""
      root.step(ok ? "réparé" : "toujours en panne")
      if (ok) {
        // Fixed. Look again: there may have been more than one thing wrong.
        root.phase = "inspect"
        doctor.todo = "recheck"
        doctor.command = [root.pluginDir + "/bin/diva-doctor", "inspect"]
        doctor.running = true
      } else if (!root.escalate("la réparation « " + t.pending + " » n'a pas suffi")) {
        // Already on her glasses: one more look, within the repair limit.
        root.callModel()
      }
    } else if (what === "recheck") {
      root.phase = ""
      var left = r && r.problems ? r.problems.length : 0
      if (left > 0 && t.repairs < 2) {
        // Something else is still wrong, and there is a repair left to spend.
        t.inspect = r
        root.step("encore " + left + " anomalie" + (left > 1 ? "s" : ""))
        root.callModel()
        return
      }
      root.task = null
      root.flash = "love"
      flashTimer.restart()
      root.answerInChat(left > 0 ? "J'ai réparé ce que je pouvais, mais il reste un souci : " + r.problems[0] + "."
                                 : "Et voilà, j'ai vérifié : tout est réparé.")
      stateTimer.restart()
    } else if (what === "report") {
      root.phase = ""
      root.task = null
      root.answerInChat("Je n'y arrive pas toute seule, et ce n'est pas toi qui as cassé quelque chose. " +
                        "J'ai noté tout ce que j'ai essayé dans un rapport pour la personne qui s'occupe de l'ordinateur.")
      if (r && r.file) root.step("rapport : " + r.file)
    }
  }

  // Out of attempts: write the diagnostic and say so plainly.
  function giveUp() {
    var t = root.task
    root.phase = "inspect"
    root.step("préparation d'un rapport")
    doctor.todo = "report"
    doctor.command = [root.pluginDir + "/bin/diva-doctor", "report",
      "Demande : " + (t ? t.request : "") + "\nEssais : " + JSON.stringify(t ? t.attempts : [])]
    doctor.running = true
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
    if (root.busy) return
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

  // Switch the whole desktop to one of her themes.
  function setTheme(id) {
    if (!root.themes.some(function(t) { return t.id === id })) return
    root.theme = id
    Quickshell.execDetached(["omarchy-theme-set", id])
  }

  // "auto", "always" or "off"; applied at once rather than at the next tick.
  function setPowerMode(mode) {
    root.setSetting(["power", "mode"], mode)
    powerNow.restart()
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
      pendingConfirm: root.pendingConfirm, thinking: root.thinking, phase: root.phase, deep: root.deep, steps: root.steps,
      task: root.task ? { level: root.task.level, escalated: root.task.escalated, repairs: root.task.repairs, attempts: root.task.attempts } : null, aiEnabled: root.aiEnabled, aiStatus: root.aiStatus,
      chat: root.chat, learned: root.learned.length, windows: root.windows.length, bindings: Object.keys(root.bindings).length, commands: root.commands.length, keyStored: root.keyStored,
      settingsStatus: root.settingsStatus,
      sections: root.sections.map(function(x) { return x.id + "(" + x.tiles.length + ")" }),
      tiles: root.tiles.map(function(t) { return t.kind + ":" + t.id + ":" + t.title }) })
  }

  onPageChanged: if (page === "settings") root.checkAi()

  PetDetector { id: petting; onPetted: root.petted() }

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
  Timer {
    id: powerNow
    interval: 400
    onTriggered: { Quickshell.execDetached([root.pluginDir + "/bin/diva-power", "apply"]); stateTimer.restart() }
  }
  Timer { id: stateTimer; interval: 350; onTriggered: root.control("", "") }
  Timer { interval: 350; repeat: true; running: root.busy; onTriggered: root.dots = root.dots % 3 + 1 }
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
    path: root.home + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.theme = String(text()).trim()
  }
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
    id: runner
    stdout: StdioCollector { onStreamFinished: root.ran(text) }
  }
  Process {
    id: doctor
    property string todo: ""
    stdout: StdioCollector { onStreamFinished: root.doctored(doctor.todo, text) }
  }
  // Applications installed or removed while the menu is up show at once.
  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() {
      root.apps = root.appList()
      if (root.opened && root.page === "home" && !root.chatting) root.refresh()
    }
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
                glasses: root.deep
                animate: root.animate && root.opened
                lookX: root.lookX
                lookY: root.lookY
                near: root.near
                onClicked: root.poked()
              }

              Item {
                width: parent.width - avatar.width - parent.spacing - Style.space(110)
                height: avatar.height

                DivaBubble {
                  id: bubble
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  side: "left"
                  width: Math.min(parent.width, said.implicitWidth + Style.space(36) + tail)
                  height: Math.max(Style.space(46), said.implicitHeight + Style.space(24))
                  radius: Style.space(22)
                  tail: Style.space(9)
                  fill: Qt.rgba(1, 1, 1, 0.11)
                  line: root.hairline
                  Behavior on width { NumberAnimation { duration: root.ms(180); easing.type: Easing.OutCubic } }
                  Behavior on height { NumberAnimation { duration: root.ms(180); easing.type: Easing.OutCubic } }

                  SequentialAnimation {
                    running: root.busy && root.animate
                    loops: Animation.Infinite
                    onStopped: bubble.opacity = 1
                    NumberAnimation { target: bubble; property: "opacity"; to: 0.6; duration: 500; easing.type: Easing.InOutSine }
                    NumberAnimation { target: bubble; property: "opacity"; to: 1; duration: 500; easing.type: Easing.InOutSine }
                  }

                  Text {
                    id: said
                    textFormat: Text.PlainText
                    x: bubble.bodyX + Style.space(18)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, bubble.parent.width - bubble.tail - Style.space(36))
                    text: root.hint
                    color: root.ink
                    font.family: root.voiceFamily
                    font.pixelSize: Style.space(16)
                    wrapMode: Text.WordWrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                    // Each new sentence fades in.
                    onTextChanged: if (!root.busy) sayIn.restart()
                    NumberAnimation { id: sayIn; target: said; property: "opacity"; from: 0.2; to: 1; duration: root.ms(220) }
                  }
                }
              }
            }

            // Her little terminal: what she is really doing, step by step, and
            // a way to stop her.
            Rectangle {
              id: terminal
              visible: root.page === "home" && (root.busy || root.steps.length > 0) && (root.chatting || root.busy)
              width: parent.width
              height: visible ? lines.implicitHeight + Style.space(20) : 0
              radius: Style.space(16)
              color: Qt.rgba(0.09, 0.05, 0.13, 0.7)
              border.width: 1
              border.color: Qt.rgba(0.79, 0.69, 0.93, 0.35)

              Column {
                id: lines
                x: Style.space(14)
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - stopButton.width - Style.space(40)
                spacing: Style.space(2)
                Repeater {
                  model: root.steps.length ? root.steps : [root.deep ? "réflexion approfondie" : "réflexion"]
                  Text {
                    required property string modelData
                    required property int index
                    textFormat: Text.PlainText
                    width: lines.width
                    text: "› " + modelData
                    color: index === (root.steps.length || 1) - 1 ? "#e7d5ff" : "#a892c4"
                    font.family: Style.font.family
                    font.pixelSize: Style.space(12)
                    elide: Text.ElideRight
                  }
                }
              }
              DivaButton {
                id: stopButton
                visible: root.busy
                anchors.right: parent.right
                anchors.rightMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                diva: root
                glyph: "close"
                text: "Arrêter"
                onClicked: root.stop()
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
                    if (root.busy) root.stop()
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
              source: root.page === "plugins" ? "PluginsPage.qml" : root.page === "settings" ? "SettingsPage.qml" : "ControlPage.qml"
              onLoaded: { item.diva = root; if ("section" in item) item.section = Qt.binding(function() { return root.page }); pageIn.restart() }
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
