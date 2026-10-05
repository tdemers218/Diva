.pragma library

// Diva's local action registry: every request Diva can answer without a
// model. Each action is a fixed argv handed to an Omarchy command, found by
// plain French phrase aliases. Nothing here builds a shell string or runs
// text the user typed. Everything she reads is in French.

// Words that carry no intent on their own ("ouvre mon navigateur" -> navigateur).
var STOP = ["a", "ai", "aide", "aider", "au", "aux", "c", "ca", "ce", "comment", "faire", "met", "mets", "mettre", "d", "de", "des", "du", "en", "est", "et", "il",
            "j", "je", "l", "la", "lance", "lancer", "le", "les", "m", "ma", "me", "mes", "moi", "mon",
            "montre", "montrer", "n", "on", "ou", "ouvre", "ouvrir", "peux", "plait", "pour", "que", "s", "sont",
            "stp", "sur", "t", "te", "tu", "un", "une", "veux", "voudrais"]

// `phrases` are what she might type or say, without accents; `reply` is what
// Diva answers; `glyph` names an icon in Icons.js; `stay` keeps the menu open so the button can be pressed again;
// `confirm` is a question she asks first, for things that cannot be undone.
var ACTIONS = [
  { id: "browser", title: "Internet", glyph: "web", reply: "C'est parti !",
    phrases: ["navigateur", "internet", "web", "google", "site", "aller en ligne"],
    effect: { type: "exec", argv: ["omarchy-launch-browser"] } },
  { id: "movie", title: "Films et séries", glyph: "movie", reply: "Choisis où regarder",
    phrases: ["regarder film", "film", "films", "regarder serie", "serie", "series", "regarder tele", "streaming", "cinema"],
    effect: { type: "group", group: "movie" } },
  { id: "windows", title: "Mes fenêtres", glyph: "windows", reply: "Voilà tes fenêtres",
    phrases: ["fenetres", "mes fenetres", "fenetres ouvertes", "retrouver fenetre", "changer fenetre", "applications ouvertes"],
    effect: { type: "group", group: "windows" } },
  { id: "files", title: "Mes fichiers", glyph: "folder", reply: "Voilà tes fichiers",
    phrases: ["fichiers", "dossiers", "explorateur", "mes affaires"],
    effect: { type: "exec", argv: ["omarchy-launch-nautilus"] } },
  { id: "downloads", title: "Téléchargements", glyph: "download", reply: "Voilà tes téléchargements",
    phrases: ["telechargements", "telecharge", "fichiers telecharges", "dossier telechargements"],
    effect: { type: "folder", dir: "DOWNLOAD" } },
  { id: "pictures", title: "Mes photos", glyph: "image", reply: "Voilà tes photos",
    phrases: ["photos", "images", "captures", "captures ecran"],
    effect: { type: "folder", dir: "PICTURES" } },
  { id: "documents", title: "Mes documents", glyph: "file", reply: "Voilà tes documents",
    phrases: ["documents", "docs", "papiers"],
    effect: { type: "folder", dir: "DOCUMENTS" } },
  { id: "volume-up", title: "Plus fort", glyph: "volume-high", reply: "Un peu plus fort", stay: true,
    phrases: ["plus fort", "monte volume", "monter volume", "monte son", "augmente volume", "augmente son",
              "volume plus", "entends rien", "pas assez fort"],
    effect: { type: "exec", argv: ["omarchy-audio-output-volume", "raise"] } },
  { id: "volume-down", title: "Moins fort", glyph: "volume-low", reply: "Un peu moins fort", stay: true,
    phrases: ["moins fort", "baisse volume", "baisser volume", "baisse son", "diminue volume", "diminue son",
              "volume moins", "trop fort"],
    effect: { type: "exec", argv: ["omarchy-audio-output-volume", "lower"] } },
  { id: "mute", title: "Couper le son", glyph: "volume-off", reply: "C'est fait", stay: true,
    phrases: ["couper son", "coupe son", "muet", "silence", "remettre son", "remets son", "volume muet", "sans son"],
    effect: { type: "exec", argv: ["omarchy-audio-output-volume", "mute-toggle"] } },
  { id: "brightness-up", title: "Plus lumineux", glyph: "sun", reply: "Plus de lumière", stay: true,
    phrases: ["plus lumineux", "plus clair", "augmente luminosite", "monte luminosite", "luminosite plus",
              "trop sombre", "ecran trop sombre", "ecran plus clair"],
    effect: { type: "exec", argv: ["omarchy-brightness-display", "+10%"] } },
  { id: "brightness-down", title: "Moins lumineux", glyph: "moon", reply: "Plus doux pour les yeux", stay: true,
    phrases: ["moins lumineux", "plus sombre", "baisse luminosite", "diminue luminosite", "luminosite moins",
              "trop lumineux", "trop clair", "ecran trop lumineux", "ecran moins clair"],
    effect: { type: "exec", argv: ["omarchy-brightness-display", "10%-"] } },
  { id: "wifi", title: "Wi-Fi", glyph: "wifi", reply: "Choisis ton réseau",
    phrases: ["wifi", "wi fi", "reseau", "connexion internet", "connecter internet", "internet marche pas",
              "pas internet"],
    effect: { type: "exec", argv: ["omarchy-shell", "shell", "toggle", "omarchy.network"] } },
  { id: "bluetooth", title: "Écouteurs", glyph: "headphones", reply: "Choisis tes écouteurs",
    phrases: ["bluetooth", "connecter ecouteurs", "ecouteurs", "casque", "connecter casque", "airpods",
              "enceinte", "connecter enceinte"],
    effect: { type: "exec", argv: ["omarchy-shell", "shell", "toggle", "omarchy.bluetooth"] } },
  { id: "sound", title: "Réglages du son", glyph: "music", reply: "Voilà les réglages du son",
    phrases: ["reglages son", "audio", "haut parleurs", "micro", "microphone", "son", "volume"],
    effect: { type: "exec", argv: ["omarchy-shell", "shell", "toggle", "omarchy.audio"] } },
  { id: "wallpaper", title: "Changer le fond", glyph: "wallpaper", reply: "Et hop, un nouveau fond", stay: true,
    phrases: ["changer fond", "change fond", "nouveau fond", "fond suivant"],
    effect: { type: "exec", argv: ["omarchy-theme-bg-next"] } },
  { id: "lock", title: "Verrouiller", glyph: "lock", reply: "À tout de suite",
    phrases: ["verrouiller", "verrouille", "verrouiller ordinateur", "bloquer ecran", "verrouiller ecran"],
    effect: { type: "exec", argv: ["omarchy-system-lock"] } },
  { id: "reboot", title: "Redémarrer", glyph: "restart", reply: "À tout de suite",
    confirm: "Redémarrer l'ordinateur ? Clique encore pour confirmer.",
    phrases: ["redemarrer", "redemarre", "redemarre ordinateur", "redemarrer ordinateur", "relancer ordinateur"],
    effect: { type: "exec", argv: ["omarchy-system-reboot"] } },
  { id: "shutdown", title: "Éteindre", glyph: "power", reply: "Bonne nuit",
    confirm: "Éteindre l'ordinateur ? Clique encore pour confirmer.",
    phrases: ["eteindre", "eteins", "eteins ordinateur", "eteindre ordinateur", "arreter ordinateur", "fermer ordinateur"],
    effect: { type: "exec", argv: ["omarchy-system-shutdown"] } }
]

// Lowercase, accents removed, punctuation and apostrophes turned into spaces.
function words(text) {
  return String(text || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9]+/g, " ").trim().split(" ").filter(function(w) { return w.length > 0 })
}

function tokens(text) {
  return words(text).filter(function(w) { return STOP.indexOf(w) < 0 })
}

// Edit distance, capped: returns `max + 1` as soon as it is exceeded.
function distance(a, b, max) {
  if (Math.abs(a.length - b.length) > max) return max + 1
  var prev = []
  for (var j = 0; j <= b.length; j++) prev.push(j)
  for (var i = 1; i <= a.length; i++) {
    var cur = [i], low = i
    for (var k = 1; k <= b.length; k++) {
      var v = Math.min(prev[k] + 1, cur[k - 1] + 1, prev[k - 1] + (a.charAt(i - 1) === b.charAt(k - 1) ? 0 : 1))
      cur.push(v)
      if (v < low) low = v
    }
    if (low > max) return max + 1
    prev = cur
  }
  return prev[b.length]
}

// Fuzzy: 0..1 when the typed letters appear in order inside the word and
// start it ("frfx" in "firefox", "tlchrg" in "telechargements"); 0 otherwise.
// The more letters skipped, the weaker the match.
function fuzzy(typed, word) {
  if (typed.length < 3 || typed.length >= word.length || typed.charAt(0) !== word.charAt(0)) return 0
  var i = 0, last = -1, gaps = 0
  for (var j = 0; j < word.length && i < typed.length; j++) {
    if (word.charAt(j) !== typed.charAt(i)) continue
    if (last >= 0) gaps += j - last - 1
    last = j
    i++
  }
  if (i < typed.length) return 0
  // Three letters must cover a short word to count; otherwise anything matches.
  if (typed.length === 3 && word.length > 6) return 0
  return Math.max(0.45, 0.72 - gaps * 0.03)
}

// How well a typed word finds a word of a name (an application, a window,
// a setting): 1 for its beginning, less for a fuzzy match, 0 for none.
function loose(typed, word) {
  if (word.indexOf(typed) === 0) return 1
  return fuzzy(typed, word)
}

// How well a typed word matches a phrase word, 0..1: equal, the start of it
// (still typing: "telech"), a plural s apart, or a typo apart on a word long
// enough for that to be safe ("telechargemnts").
function wordMatches(typed, word) {
  if (typed === word) return 1
  if (typed.length >= 2 && word.indexOf(typed) === 0) return 1
  if (typed.length > 3 && (typed === word + "s" || typed + "s" === word)) return 1
  var shortest = Math.min(typed.length, word.length)
  if (shortest >= 8 && distance(typed, word, 2) <= 2) return 0.8
  if (shortest >= 5 && distance(typed, word, 1) <= 1) return 0.8
  // Phrases are full of short everyday words, so fuzzy needs four letters here.
  return typed.length >= 4 ? fuzzy(typed, word) * 0.9 : 0
}

// 0 when the request does not fit these phrases; otherwise up to 100, higher
// the more of the phrase the request covers and the fewer typos it took.
// Every meaningful word must be accounted for, so "baisse le volume" never
// reaches "Plus fort".
function phraseScore(query, phrases) {
  var q = tokens(query)
  if (!q.length) return 0
  var best = 0
  for (var p = 0; p < phrases.length; p++) {
    var phrase = words(phrases[p])
    var quality = 1
    for (var i = 0; i < q.length && quality > 0; i++) {
      var hit = 0
      for (var j = 0; j < phrase.length; j++) hit = Math.max(hit, wordMatches(q[i], phrase[j]))
      quality = Math.min(quality, hit)
    }
    if (quality === 0) continue
    var s = Math.round((50 + 50 * Math.min(1, q.length / phrase.length)) * quality)
    if (s > best) best = s
  }
  return best
}

function score(query, action) {
  return phraseScore(query, action.phrases)
}

// The argv an action runs. `dirs` maps XDG names (DOWNLOAD, PICTURES,
// DOCUMENTS) to absolute paths.
function argv(action, config, dirs) {
  var e = action.effect
  if (e.type === "folder") return ["uwsm-app", "--", "nautilus", "--new-window", String(dirs[e.dir] || dirs.HOME)]
  // A group opens a choice of tiles in the menu; it runs nothing itself.
  if (e.type === "group") return null
  return e.argv.slice()
}

function tile(action, value) {
  return { kind: "action", id: action.id, title: action.title, glyph: action.glyph, icon: "", score: value }
}

function byId(id) {
  for (var i = 0; i < ACTIONS.length; i++) if (ACTIONS[i].id === id) return ACTIONS[i]
  return null
}

// Her favourite places, shown as app icons before she types anything.
var HOME = ["browser", "movie", "windows", "files", "downloads", "pictures", "documents"]

function home() {
  return HOME.map(function(id, i) { return tile(byId(id), 100 - i) })
}

// Actions answering a request, best first. An empty request lists them all.
function match(query) {
  var out = []
  var empty = words(query).length === 0
  for (var i = 0; i < ACTIONS.length; i++) {
    var value = empty ? 100 - i : score(query, ACTIONS[i])
    if (value > 0) out.push(tile(ACTIONS[i], value))
  }
  out.sort(function(a, b) { return b.score - a.score })
  return out
}

// Installed applications whose name answers the request. `apps` is a list of
// { id, name, icon }; a name matches when every typed word starts one of its
// words.
function matchApps(query, apps, limit) {
  var q = tokens(query)
  if (!q.length) return []
  var out = []
  for (var i = 0; i < apps.length; i++) {
    var name = words(apps[i].name)
    if (!name.length) continue
    var quality = 1
    for (var k = 0; k < q.length && quality > 0; k++) {
      var hit = 0
      for (var j = 0; j < name.length; j++) hit = Math.max(hit, loose(q[k], name[j]))
      quality = Math.min(quality, hit)
    }
    if (quality > 0)
      out.push({ kind: "app", id: apps[i].id, title: apps[i].name, glyph: "", icon: apps[i].icon,
                 score: Math.round((name[0].indexOf(q[0]) === 0 ? 60 : 40) * quality) })
  }
  out.sort(function(a, b) { return b.score - a.score || a.title.localeCompare(b.title) })
  return out.slice(0, limit)
}
