import QtQuick
import QtTest
import "../plugin/core/Actions.js" as Actions
import "../plugin/core/Smart.js" as Smart
import "../plugin/core/Icons.js" as Icons

TestCase {
  name: "DivaActions"

  readonly property var dirs: ({ HOME: "/home/elle", DOWNLOAD: "/home/elle/Téléchargements",
                                 PICTURES: "/home/elle/Images", DOCUMENTS: "/home/elle/Documents" })

  function ids(query) { return Actions.match(query).map(function(t) { return t.id }) }
  function first(query) { return Actions.match(query)[0].id }
  function argv(id, config) { return Actions.argv(Actions.byId(id), config || {}, dirs) }

  // The example requests from the project brief, as she would say them.
  function test_brief_examples() {
    compare(first("Ouvre mon navigateur."), "browser")
    compare(first("Baisse le volume."), "volume-down")
    compare(first("Aide-moi à connecter mes écouteurs."), "bluetooth")
    compare(first("Où sont mes téléchargements ?"), "downloads")
    compare(first("Je veux regarder un film."), "movie")
  }

  function test_accents_and_apostrophes_do_not_matter() {
    compare(first("telechargements"), "downloads")
    compare(first("TÉLÉCHARGEMENTS"), "downloads")
    compare(first("j'entends rien"), "volume-up")
    compare(first("l'écran est trop sombre"), "brightness-up")
  }

  function test_direction_is_never_confused() {
    compare(ids("baisse le volume"), ["volume-down"])
    compare(ids("monte le volume"), ["volume-up"])
    compare(ids("c'est trop fort"), ["volume-down"])
    compare(ids("plus fort"), ["volume-up"])
    compare(ids("moins fort"), ["volume-down"])
    compare(ids("trop lumineux"), ["brightness-down"])
  }

  function test_ambiguous_request_offers_choices() {
    var found = ids("volume")
    verify(found.indexOf("volume-up") >= 0)
    verify(found.indexOf("volume-down") >= 0)
    verify(found.indexOf("sound") >= 0)
  }

  function test_partial_typing() {
    compare(first("telech"), "downloads")
    compare(first("blue"), "bluetooth")
  }

  function test_stays_quiet_when_unsure() {
    compare(ids("ouvre"), [])
    compare(ids("déclaration d'impôts"), [])
    compare(ids("volume de travers"), [])
  }

  function test_empty_request_lists_everything() {
    compare(ids("").length, Actions.ACTIONS.length)
    compare(ids("   ").length, Actions.ACTIONS.length)
    compare(first(""), "browser")
  }

  function test_effects_are_fixed_argv() {
    compare(argv("downloads"), ["uwsm-app", "--", "nautilus", "--new-window", "/home/elle/Téléchargements"])
    compare(argv("volume-up"), ["omarchy-audio-output-volume", "raise"])
    for (var i = 0; i < Actions.ACTIONS.length; i++) {
      var a = Actions.ACTIONS[i]
      if (["group", "page", "screensaver"].indexOf(a.effect.type) < 0) verify(argv(a.id).length > 0)
    }
  }

  function test_films_open_a_choice() {
    compare(Actions.byId("movie").effect, { type: "group", group: "movie" })
    compare(argv("movie"), null)
    var none = Smart.movieTiles([])
    compare(none.map(function(t) { return t.kind + ":" + t.id }), ["install:youtube", "install:netflix", "install:stremio"])
    compare(none[2].title, "Installer Stremio")
    verify(none[2].confirm.length > 0)
    // Installed apps are opened, by desktop id for the Flatpak and by name for web apps.
    var have = [{ id: "YouTube", name: "YouTube", icon: "youtube" }, { id: "com.stremio.Stremio", name: "Stremio", icon: "stremio" }]
    compare(Smart.movieTiles(have).map(function(t) { return t.kind + ":" + t.id }),
            ["app:YouTube", "install:netflix", "app:com.stremio.Stremio"])
    compare(Smart.resolve("", { apps: have, group: "movie" }).tiles.length, 3)
    // Before she types, her favourites; the rest lives in the control centre.
    compare(Smart.resolve("", { apps: have }).tiles.map(function(t) { return t.id }), Actions.HOME)
    // Installing runs Diva's own helper with a fixed name, nothing else.
    compare(Smart.argv(none[2], {}, dirs, "/p"), ["/p/bin/diva-install", "stremio"])
    compare(Smart.argv({ kind: "install", id: "x; rm -rf ~" }, {}, dirs, "/p"), null)
    compare(Smart.argv(none[2], {}, dirs, ""), null)
    compare(Smart.resolve("netflix", { apps: [], now: noon }).tiles[0].id, "netflix")
    compare(Smart.resolve("stremio", { apps: have, now: noon }).tiles[0].kind, "app")
  }

  function test_power_actions_ask_first() {
    compare(first("éteins l'ordinateur"), "shutdown")
    compare(first("redémarrer"), "reboot")
    verify(Actions.byId("shutdown").confirm.length > 0)
    verify(Actions.byId("reboot").confirm.length > 0)
    compare(ids("verrouiller l'ordinateur"), ["lock"])
  }

  function test_apps() {
    var apps = [{ id: "spotify", name: "Spotify", icon: "spotify" }, { id: "org.gnome.Calculator", name: "Calculatrice", icon: "calc" },
                { id: "libreoffice-writer", name: "LibreOffice Writer", icon: "lo" }]
    compare(Actions.matchApps("ouvre spotify", apps, 5).map(function(t) { return t.id }), ["spotify"])
    compare(Actions.matchApps("calc", apps, 5)[0].id, "org.gnome.Calculator")
    compare(Actions.matchApps("writer", apps, 5)[0].id, "libreoffice-writer")
    compare(Actions.matchApps("", apps, 5), [])
    compare(Actions.matchApps("xyz", apps, 5), [])
  }

  function test_every_action_is_french_and_complete() {
    var seen = {}
    for (var i = 0; i < Actions.ACTIONS.length; i++) {
      var a = Actions.ACTIONS[i]
      verify(!seen[a.id]); seen[a.id] = true
      verify(a.title && a.reply && a.phrases.length > 0)
      // Every icon name exists, and nothing she reads carries an emoji.
      verify(Icons.MAP[a.glyph] !== undefined)
      verify(!/[\u2600-\u27BF\uD83C-\uDBFF]/.test(a.title + a.reply + (a.confirm || "")))
      // Phrases are stored without accents; a stray accent would never match.
      for (var p = 0; p < a.phrases.length; p++) compare(Actions.words(a.phrases[p]).join(" "), a.phrases[p])
    }
  }

  // ---------------------------------------------------------------- Smart

  readonly property var apps: [{ id: "spotify", name: "Spotify", icon: "spotify" },
                               { id: "libreoffice-calc", name: "LibreOffice Calc", icon: "calc" }]
  readonly property var noon: new Date(2026, 9, 4, 21, 5)

  function kinds(query, extra) {
    var ctx = { apps: apps, learned: [], aiEnabled: false, now: noon }
    for (var k in (extra || {})) ctx[k] = extra[k]
    return Smart.resolve(query, ctx).tiles.map(function(t) { return t.kind + ":" + t.id })
  }

  function test_typos_are_forgiven() {
    compare(first("telechargemnts"), "downloads")
    compare(first("navigateu"), "browser")
    compare(first("ecouteur"), "bluetooth")
    compare(first("verouiller"), "lock")
    // Short words are never guessed: "fort" must not become "font".
    compare(ids("fart"), [])
  }

  function test_levels() {
    compare(kinds("mets le volume à 40")[0], "volume:volume-40")
    compare(kinds("son à 30 %")[0], "volume:volume-30")
    compare(kinds("luminosité au max")[0], "brightness:brightness-100")
    compare(kinds("volume à 250")[0], "volume:volume-100")
    compare(kinds("mets le son à fond")[0], "volume:volume-100")
    // A wallpaper is not a brightness level.
    verify(kinds("fond d'écran").every(function(k) { return k.indexOf("brightness") !== 0 }))
    compare(Smart.argv(Smart.levelTile("volume", 40), {}, dirs), ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "0.40"])
    compare(Smart.argv(Smart.levelTile("brightness", 0), {}, dirs), ["omarchy-brightness-display", "1%"])
  }

  function test_calculator() {
    compare(Smart.calculate("12*4"), "48")
    compare(Smart.calculate("3,5 + 1,5"), "5")
    compare(Smart.calculate("(2+3) x 4"), "20")
    compare(Smart.calculate("10 / 4"), "2,5")
    compare(Smart.calculate("1/0"), null)
    compare(Smart.calculate("2+"), null)
    compare(Smart.calculate("42"), null)
    compare(Smart.calculate("process.exit()"), null)
    compare(kinds("12*4"), ["calc:calc"])
  }

  function test_answers() {
    compare(Smart.resolve("quelle heure est-il ?", { apps: [], now: noon }).answer, "Il est 21 h 05.")
    compare(Smart.resolve("on est quel jour", { apps: [], now: noon }).answer, "On est dimanche 4 octobre 2026.")
    compare(Smart.resolve("baisse le volume", { apps: [], now: noon }).answer, "")
  }

  function test_sites_and_search() {
    compare(kinds("youtube")[0], "install:youtube")
    compare(kinds("mes mails")[0], "url:url:https://mail.google.com")
    compare(kinds("cherche une recette de crêpes"), ["search:search"])
    var tile = Smart.resolve("cherche une recette de crêpes", { apps: [], now: noon }).tiles[0]
    compare(Smart.argv(tile, {}, dirs), ["omarchy-launch-browser", "https://www.google.com/search?q=une%20recette%20de%20cr%C3%AApes"])
    // Unknown requests always keep a way forward.
    compare(kinds("comment faire un gâteau au chocolat"), ["search:search"])
    compare(kinds("comment faire un gâteau au chocolat", { aiEnabled: true }), ["ai:ai", "search:search"])
    // A known request is not buried under the assistant.
    compare(kinds("baisse le volume", { aiEnabled: true })[0], "action:volume-down")
  }

  function test_intents_are_checked() {
    compare(Smart.intentTile({ type: "action", id: "wifi" }, apps).id, "wifi")
    compare(Smart.intentTile({ type: "action", id: "format-disk" }, apps), null)
    compare(Smart.intentTile({ type: "app", name: "spotify" }, apps).id, "spotify")
    compare(Smart.intentTile({ type: "app", name: "Photoshop" }, apps), null)
    compare(Smart.intentTile({ type: "url", url: "https://www.sncf-connect.com/billets" }, apps).kind, "url")
    compare(Smart.intentTile({ type: "url", url: "http://exemple.fr" }, apps), null)
    compare(Smart.intentTile({ type: "url", url: "file:///etc/passwd" }, apps), null)
    compare(Smart.intentTile({ type: "url", url: "https://a.fr/$(rm -rf ~)" }, apps), null)
    // Shell syntax in an address stays one inert argument; nothing interprets it.
    compare(Smart.argv(Smart.intentTile({ type: "url", url: "https://a.fr/$(id)" }, apps), {}, dirs), ["omarchy-launch-browser", "https://a.fr/$(id)"])
    compare(Smart.intentTile({ type: "volume", percent: 999 }, apps).percent, 100)
    compare(Smart.intentTile({ type: "shell", command: "rm -rf ~" }, apps), null)
    compare(Smart.intentTile({ type: "none" }, apps), null)
    compare(Smart.intentTile(null, apps), null)
  }

  function test_learned_shortcuts() {
    var tile = Smart.intentTile({ type: "action", id: "wifi" }, apps)
    var entry = { key: Smart.learnedKey("Internet est tout lent ce soir"), intent: Smart.tileIntent(tile) }
    compare(entry.intent, { type: "action", id: "wifi" })
    // The same words, however they are written, now answer without the assistant.
    var again = Smart.resolve("internet est tout lent ce soir !", { apps: apps, learned: [entry], aiEnabled: true, now: noon }).tiles
    compare(again[0].kind + ":" + again[0].id, "action:wifi")
    compare(again[0].learned, true)
    // A shortcut to something that no longer exists is ignored.
    var gone = [{ key: Smart.learnedKey("lance photoshop"), intent: { type: "app", name: "Photoshop" } }]
    compare(Smart.resolve("lance photoshop", { apps: apps, learned: gone, now: noon }).tiles[0].kind, "search")
    compare(Smart.tileIntent(Smart.searchTile("x")), null)
  }

  // --------------------------------------------------- Omarchy commands

  readonly property string menuText: '{\n  // Root\n  "update": {"icon":"x","label":"Update"},\n' +
    '  "update.omarchy": {"label":"Omarchy","action":"omarchy-launch-floating-terminal-with-presentation omarchy-update"}, // run it\n' +
    '  "setup": {"label":"Setup"},\n  "setup.wifi": {"label":"Wi-Fi","action":"omarchy-launch-wifi"},\n' +
    '  /* block */ "learn.site": {"label":"Docs","action":"xdg-open https://omarchy.org//manual"},\n' +
    '  "bad id!": {"label":"Nope","action":"rm -rf ~"},\n}'
  readonly property string userText: '{ "setup.wifi": {"label":"Wireless"}, "personal.notes": {"label":"Notes","action":"x"} }'

  function test_omarchy_menu_is_parsed() {
    var commands = Smart.parseCommands([menuText, userText])
    var ids = commands.map(function(c) { return c.id }).sort()
    compare(ids, ["learn.site", "personal.notes", "setup", "setup.wifi", "update", "update.omarchy"])
    var update = commands.filter(function(c) { return c.id === "update.omarchy" })[0]
    compare(update.label, "Omarchy")
    compare(update.path, "Update")
    // The user's extension file overrides a label and keeps the action.
    compare(commands.filter(function(c) { return c.id === "setup.wifi" })[0].label, "Wireless")
    compare(Smart.parseCommands(["not json"]), [])
  }

  function test_omarchy_commands_stay_out_of_the_way() {
    var commands = Smart.parseCommands([menuText])
    var ctx = { apps: apps, learned: [], now: noon, commands: commands, showCommands: true }
    // Diva's own answer comes first; Omarchy's entries follow it.
    var wifi = Smart.resolve("wifi", ctx).tiles.map(function(t) { return t.kind + ":" + t.id })
    compare(wifi[0], "action:wifi")
    verify(wifi.indexOf("omarchy:setup.wifi") > 0)
    // Off unless asked for.
    ctx.showCommands = false
    verify(Smart.resolve("update", ctx).tiles.every(function(t) { return t.kind !== "omarchy" }))
    // ">" shows only Omarchy's commands, whatever the setting.
    // The submenu itself comes first, then what is inside it.
    compare(Smart.resolve("> update", ctx).tiles.map(function(t) { return t.id }), ["update", "update.omarchy"])
    compare(Smart.resolve(">", ctx).tiles, [])
    var tile = Smart.resolve("> update", ctx).tiles[1]
    compare(Smart.argv(tile, {}, dirs), ["omarchy-menu", "summon", "update.omarchy"])
    compare(Smart.argv({ kind: "omarchy", id: "x; rm -rf ~" }, {}, dirs), null)
  }

  // ------------------------------------------------------------ settings

  function test_her_settings_are_found_by_name() {
    function found(q) { return Smart.resolve(q, { apps: [], now: noon }).tiles.map(function(t) { return t.kind + ":" + t.id }) }
    verify(found("réglages").indexOf("setting:settings") >= 0)
    verify(found("changer mon prénom").indexOf("setting:name") >= 0)
    verify(found("assistante").indexOf("setting:assistant") >= 0)
    verify(found("extensions").indexOf("setting:extensions") >= 0)
    verify(found("fond d'écran").indexOf("setting:wallpaper-pick") >= 0)
    compare(Smart.argv({ kind: "setting", id: "wallpaper-pick" }, {}, dirs), ["omarchy-theme-bg-switcher"])
    compare(Smart.argv({ kind: "setting", id: "settings" }, {}, dirs), null)
  }

  function test_omarchy_settings_are_found_in_french() {
    var menu = '{ "style": {"label":"Style"}, "style.font": {"label":"Font","action":"a"}, "style.theme": {"label":"Theme","action":"b"},' +
      ' "setup": {"label":"Setup"}, "setup.monitors": {"label":"Monitors","action":"c"}, "update": {"label":"Update"},' +
      ' "update.timezone": {"label":"Timezone","action":"d"}, "setup.keybindings": {"label":"Keybindings","action":"e"} }'
    var commands = Smart.parseCommands([menu])
    function found(q) {
      return Smart.resolve(q, { apps: [], now: noon, commands: commands, showCommands: true }).tiles
        .filter(function(t) { return t.kind === "omarchy" }).map(function(t) { return t.id })
    }
    compare(found("police")[0], "style.font")
    compare(found("thème")[0], "style.theme")
    compare(found("écran")[0], "setup.monitors")
    compare(found("fuseau horaire"), ["update.timezone"])
    compare(found("raccourcis clavier"), ["setup.keybindings"])
    compare(found("mise à jour")[0], "update")
    // English still works.
    compare(found("font")[0], "style.font")
  }

  function test_every_icon_name_exists() {
    var names = []
    Smart.SITES.concat(Smart.MOVIES).concat(Smart.SETTINGS).forEach(function(x) { names.push(x.glyph) })
    names = names.concat(["volume-high", "sun", "magnify", "link", "creation", "calculator", "cog", "star", "arrow-left", "check", "download", "account", "images", "puzzle", "update"])
    for (var i = 0; i < names.length; i++) verify(Icons.MAP[names[i]] !== undefined, names[i])
  }

  function test_questions_go_to_the_assistant_first() {
    function order(q, on) { return kinds(q, { aiEnabled: on }) }
    compare(order("comment faire un gâteau au chocolat", true)[0], "ai:ai")
    compare(order("tu connais un bon film pour ce soir ?", true)[0], "ai:ai")
    compare(order("pourquoi le ciel est bleu", true)[0], "ai:ai")
    // Without the assistant, the web is the way forward.
    compare(order("pourquoi le ciel est bleu", false), ["search:search"])
    // What Diva knows exactly stays hers, question or not.
    compare(order("Où sont mes téléchargements ?", true)[0], "action:downloads")
    compare(order("baisse le volume", true)[0], "action:volume-down")
    compare(order("cherche une recette de crêpes", true)[0], "search:search")
    verify(Smart.looksLikeQuestion("ça va ?"))
    verify(!Smart.looksLikeQuestion("wifi"))
  }

  function test_reminders() {
    var r = Smart.parseReminder("rappelle-moi dans 10 minutes de sortir le gâteau")
    compare(r.minutes, 10)
    compare(r.text, "sortir le gâteau")
    compare(r.title, "Rappel dans 10 min")
    compare(Smart.argv(r, {}, dirs), ["omarchy-reminder", "10", "sortir le gâteau"])
    compare(Smart.parseReminder("Rappel dans 2 heures : appeler maman !").minutes, 120)
    compare(Smart.parseReminder("Rappel dans 2 heures : appeler maman !").text, "appeler maman")
    compare(Smart.parseReminder("minuteur 5 min").text, "")
    compare(Smart.argv(Smart.parseReminder("minuteur 5 min"), {}, dirs), ["omarchy-reminder", "5", "Rappel"])
    // Her words stay one inert argument.
    compare(Smart.argv(Smart.parseReminder("rappelle moi dans 3 min de $(rm -rf ~); id"), {}, dirs)[2], "$(rm -rf ~); id")
    compare(Smart.parseReminder("dans 10 minutes"), null)
    compare(Smart.parseReminder("rappelle-moi dans 9999 minutes"), null)
    compare(Smart.parseReminder("rappelle-moi de sortir"), null)
    compare(kinds("rappelle-moi dans 15 minutes d'appeler Léa")[0], "reminder:reminder")
    // "son" in the message must not become a volume level.
    verify(kinds("rappelle-moi dans 5 minutes de baisser le son").every(function(k) { return k.indexOf("volume") !== 0 }))
  }

  function test_battery_answer() {
    var ctx = { apps: [], now: noon, state: { battery: 82, charging: false } }
    compare(Smart.resolve("il me reste combien de batterie", ctx).answer, "Il te reste 82 % de batterie.")
    ctx.state.charging = true
    compare(Smart.resolve("batterie", ctx).answer, "Il te reste 82 % de batterie, et elle se recharge.")
    compare(Smart.resolve("batterie", { apps: [], now: noon }).answer, "")
    compare(Smart.resolve("batterie", { apps: [], now: noon, state: { battery: 64, charging: false, minutes: 205 } }).answer,
            "Il te reste 64 % de batterie, environ 3 h 25 à ce rythme.")
    compare(Smart.resolve("batterie", { apps: [], now: noon, state: { battery: 9, charging: false, minutes: 18 } }).answer,
            "Il te reste 9 % de batterie, environ 18 min à ce rythme.")
  }

  // ----------------------------------------------------------- navigation

  readonly property var open: [
    { address: "0x55bd67b53500", cls: "brave-browser", title: "recette de soupe facile - Recherche Google", workspace: 2, icon: "brave" },
    { address: "0x55bd67b46090", cls: "org.gnome.Nautilus", title: "Téléchargements", workspace: 1, icon: "" }]
  readonly property var keys: Smart.parseBindings(
    "SUPER + W                           → Close window\n" +
    "SUPER + Q                           → Close window\n" +
    "SUPER SHIFT + LEFT                  → Swap window to the left\n" +
    "SUPER + LEFT MOUSE BUTTON           → Move window\n" +
    "SUPER + MINUS                       → Expand window left\n" +
    "junk line\n")

  function nav(query, extra) {
    var ctx = { apps: apps, now: noon, windows: open, bindings: keys }
    for (var k in (extra || {})) ctx[k] = extra[k]
    return Smart.resolve(query, ctx)
  }
  function navKinds(query, extra) { return nav(query, extra).tiles.map(function(t) { return t.kind + ":" + t.id }) }

  function test_open_windows_are_found() {
    compare(navKinds("brave")[0], "window:0x55bd67b53500")
    compare(navKinds("recette soupe")[0], "window:0x55bd67b53500")
    compare(navKinds("nautilus")[0], "window:0x55bd67b46090")
    var tile = nav("brave").tiles[0]
    compare(tile.title, "Brave Browser")
    compare(Smart.appName("org.gnome.Nautilus"), "Nautilus")
    compare(Smart.argv(tile, {}, dirs, "/p"), ["/p/bin/diva-window", "focus", "0x55bd67b53500"])
    compare(Smart.argv({ kind: "window", id: "0x1; rm -rf ~" }, {}, dirs, "/p"), null)
    // "Mes fenêtres" lists them, then what can be done to the current one.
    var all = nav("", { group: "windows" }).tiles
    compare(all[0].kind, "window")
    compare(all[2].kind + ":" + all[2].id, "winact:close")
    compare(Actions.byId("windows").effect, { type: "group", group: "windows" })
  }

  function test_window_actions() {
    compare(navKinds("ferme la fenêtre")[0], "winact:close")
    compare(navKinds("plein écran")[0], "winact:fullscreen")
    compare(navKinds("fenêtre flottante")[0], "winact:float")
    compare(navKinds("mets la fenêtre à gauche")[0], "winact:left")
    compare(navKinds("plus large")[0], "winact:wider")
    function run(q) { return Smart.argv(nav(q).tiles[0], {}, dirs, "/p") }
    compare(run("ferme la fenêtre"), ["/p/bin/diva-window", "close"])
    // Resizing keeps the menu open, so it must not wait for it to close.
    compare(run("plus large"), ["/p/bin/diva-window", "wider", "--now"])
    compare(Smart.outcome(nav("plus large").tiles[0]).stay, true)
    compare(Smart.outcome(nav("plein écran").tiles[0]).stay, false)
    compare(Smart.argv({ kind: "winact", id: "format" }, {}, dirs, "/p"), null)
  }

  function test_workspaces() {
    compare(run2("envoie la fenêtre sur l'espace 2"), ["/p/bin/diva-window", "to-workspace", "2"])
    compare(run2("va sur l'espace 3"), ["/p/bin/diva-window", "goto-workspace", "3"])
    compare(run2("bureau 4"), ["/p/bin/diva-window", "goto-workspace", "4"])
    compare(Smart.parseWorkspace("espace 42"), null)
    compare(Smart.parseWorkspace("espace"), null)
    compare(Smart.argv({ kind: "winact", id: "to-workspace", number: 99 }, {}, dirs, "/p"), null)
  }
  function run2(q) { return Smart.argv(nav(q).tiles[0], {}, dirs, "/p") }

  function test_guide_uses_this_computers_keys() {
    compare(keys["Close window"], "SUPER + W")
    compare(Smart.keyLabel("SUPER SHIFT + LEFT"), "Super + Maj + ←")
    compare(Smart.keyLabel("SUPER + LEFT MOUSE BUTTON"), "Super + clic gauche")
    var close = Smart.GUIDE.filter(function(t) { return t.id === "close" })[0]
    verify(Smart.guideText(close, keys).indexOf("Super + W ferme") === 0)
    // No binding known: the fallback is said instead.
    verify(Smart.guideText(close, {}).indexOf("Super + W ferme") === 0)
    var full = Smart.GUIDE.filter(function(t) { return t.id === "fullscreen" })[0]
    verify(Smart.guideText(full, keys).indexOf("Super + F") === 0)
    verify(Smart.guideLines(keys).indexOf("- Le pavé tactile :") > 0)
    verify(!/[{}|]/.test(Smart.guideLines(keys)))
  }

  function test_how_to_questions_are_answered_here() {
    var r = nav("comment je ferme une fenêtre ?", { aiEnabled: true })
    verify(r.answer.indexOf("Super + W ferme la fenêtre") === 0)
    // Answered locally, so the assistant is offered but not first.
    verify(r.tiles[0].kind !== "ai")
    verify(nav("comment déplacer une fenêtre ?").answer.indexOf("Garde Super enfoncé") === 0)
    verify(nav("pavé tactile").tiles.some(function(t) { return t.kind === "help" && t.id === "trackpad" }))
    compare(Smart.argv({ kind: "help", id: "keys" }, {}, dirs, "/p"), ["omarchy-menu-keybindings"])
    compare(Smart.argv({ kind: "help", id: "trackpad" }, {}, dirs, "/p"), null)
    // Every guide and window icon exists.
    Smart.GUIDE.concat(Smart.WINDOW_ACTIONS).forEach(function(x) { verify(Icons.MAP[x.glyph] !== undefined, x.glyph) })
    verify(Icons.MAP["lightbulb"] !== undefined && Icons.MAP["application"] !== undefined && Icons.MAP["grid"] !== undefined)
  }

  // ------------------------------------------------------ fuzzy and layout

  function test_fuzzy_matching() {
    verify(Actions.fuzzy("frfx", "firefox") > 0)
    verify(Actions.fuzzy("tlchrg", "telechargements") > 0)
    compare(Actions.fuzzy("xyz", "firefox"), 0)
    // Letters out of order, or not starting the word, are not a match.
    compare(Actions.fuzzy("xfr", "firefox"), 0)
    compare(Actions.fuzzy("fo", "firefox"), 0)
    var many = [{ id: "firefox", name: "Firefox", icon: "" }, { id: "files", name: "Files", icon: "" },
                { id: "libreoffice-writer", name: "LibreOffice Writer", icon: "" }]
    compare(Actions.matchApps("frfx", many, 5).map(function(t) { return t.id }), ["firefox"])
    compare(Actions.matchApps("lbrwrt", many, 5), [])
    compare(Actions.matchApps("lbrf wrtr", many, 5)[0].id, "libreoffice-writer")
    // An exact beginning outranks a fuzzy find.
    compare(Actions.matchApps("fi", many, 5).length, 2)
    verify(Actions.matchApps("fire", many, 5)[0].score > Actions.matchApps("frfx", many, 5)[0].score)
    // Actions too, with four letters or more.
    compare(first("tlchrgmnt"), "downloads")
    compare(first("vrrller"), "lock")
    compare(navKinds("brv")[0], "window:0x55bd67b53500")
    // Still never confused, and still quiet when unsure.
    compare(ids("baisse le volume"), ["volume-down"])
    compare(ids("volume de travers"), [])
    compare(ids("fart"), [])
  }

  function test_results_are_laid_out_by_kind() {
    var l = Smart.layout(nav("brave", { aiEnabled: true }).tiles)
    var names = l.sections.map(function(s) { return s.id })
    compare(names[0], "windows")
    compare(names[names.length - 1], "ask")
    // An installed app of that name sits between them, as an icon to open.
    var withApp = Smart.layout(nav("brave", { apps: [{ id: "brave-browser", name: "Brave", icon: "brave" }] }).tiles)
    compare(withApp.sections.map(function(x) { return x.id }), ["windows", "open", "ask"])
    // Every tile knows where it is, and Enter runs the best one.
    for (var i = 0; i < l.flat.length; i++) compare(l.flat[i].flat, i)
    compare(l.flat[l.best].kind, "window")
    // A question puts the assistant first.
    var q = Smart.layout(nav("pourquoi le ciel est bleu ?", { aiEnabled: true }).tiles)
    compare(q.sections[0].id, "ask")
    compare(q.flat[q.best].kind, "ai")
    // A tip leads, but Enter still does the thing.
    var h = Smart.layout(nav("comment je ferme une fenêtre ?").tiles)
    compare(h.sections[0].id, "answer")
    compare(h.flat[h.best].kind + ":" + h.flat[h.best].id, "winact:close")
    // The windows view: cards, then pills.
    var w = Smart.layout(nav("", { group: "windows" }).tiles)
    compare(w.sections.map(function(s) { return s.id }), ["windows", "window"])
    compare(Smart.layout([]).flat, [])
    // Every kind has a home.
    var kindsSeen = []
    Smart.SECTIONS.forEach(function(s) { kindsSeen = kindsSeen.concat(s.kinds) })
    ;["action", "app", "url", "install", "search", "ai", "calc", "help", "window", "winact", "setting", "omarchy", "volume", "brightness", "reminder"]
      .forEach(function(k) { verify(kindsSeen.indexOf(k) >= 0, k) })
  }

  function test_screensaver_is_hers() {
    compare(first("écran de veille"), "screensaver")
    var tile = Actions.tile(Actions.byId("screensaver"), 0)
    compare(Smart.argv(tile, {}, dirs, "/p"), ["/p/bin/diva-screensaver-launch", "force"])
    compare(Smart.argv(tile, {}, dirs, ""), null)
  }

  function test_every_action_names_its_check() {
    compare(Smart.check(Actions.tile(Actions.byId("volume-up"), 0)), "state:volume:up")
    compare(Smart.check(Actions.tile(Actions.byId("mute"), 0)), "state:muted:toggle")
    compare(Smart.check(Actions.tile(Actions.byId("browser"), 0)), "launch")
    compare(Smart.check(Actions.tile(Actions.byId("lock"), 0)), "none")
    compare(Smart.check(Smart.levelTile("volume", 40)), "state:volume:=40")
    compare(Smart.check(Smart.levelTile("brightness", 0)), "state:brightness:=1")
    compare(Smart.check({ kind: "app", id: "spotify" }), "launch")
    compare(Smart.check({ kind: "window", id: "0x55bd67b53500" }), "focus:0x55bd67b53500")
    compare(Smart.check({ kind: "window", id: "0x1; id" }), "none")
    compare(Smart.check({ kind: "winact", id: "close" }), "closed")
    compare(Smart.check({ kind: "winact", id: "float" }), "float")
    compare(Smart.check({ kind: "winact", id: "wider" }), "none")
    compare(Smart.check({ kind: "help", id: "close" }), "none")
  }
}
