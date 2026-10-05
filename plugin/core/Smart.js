.pragma library
.import "Actions.js" as Actions

// What Diva understands beyond her fixed buttons, still without a model:
// levels ("volume à 40"), sums, the time, where to watch films, well-known
// sites, settings (hers and Omarchy's), web searches, shortcuts she has
// learned, and the tiles her AI assistant may ask for. Every tile ends up as
// a fixed-shape argv in `argv()`; nothing here runs text as a command.

// Where films are watched. `flatpak` is the app's official Flathub id; `url`
// is installed as an Omarchy web app, the way Omarchy ships YouTube itself.
var MOVIES = [
  { id: "youtube", title: "YouTube", glyph: "youtube", url: "https://youtube.com/", phrases: ["youtube", "video", "videos", "regarder video"] },
  { id: "netflix", title: "Netflix", glyph: "netflix", url: "https://www.netflix.com/", phrases: ["netflix"] },
  { id: "stremio", title: "Stremio", glyph: "play", flatpak: "com.stremio.Stremio", phrases: ["stremio"] }
]

var SITES = [
  { id: "gmail", title: "Gmail", glyph: "gmail", url: "https://mail.google.com", phrases: ["gmail", "mail", "mails", "email", "emails", "courriel", "courriels", "messagerie"] },
  { id: "instagram", title: "Instagram", glyph: "instagram", url: "https://www.instagram.com", phrases: ["instagram", "insta"] },
  { id: "facebook", title: "Facebook", glyph: "facebook", url: "https://www.facebook.com", phrases: ["facebook"] },
  { id: "messenger", title: "Messenger", glyph: "messenger", url: "https://www.messenger.com", phrases: ["messenger"] },
  { id: "whatsapp", title: "WhatsApp", glyph: "whatsapp", url: "https://web.whatsapp.com", phrases: ["whatsapp"] },
  { id: "tiktok", title: "TikTok", glyph: "music-note", url: "https://www.tiktok.com", phrases: ["tiktok"] },
  { id: "pinterest", title: "Pinterest", glyph: "pinterest", url: "https://www.pinterest.com", phrases: ["pinterest", "idees deco", "inspiration"] },
  { id: "maps", title: "Google Maps", glyph: "map", url: "https://maps.google.com", phrases: ["maps", "carte", "itineraire", "google maps", "plan"] },
  { id: "meteo", title: "Météo", glyph: "weather", url: "https://www.google.com/search?q=m%C3%A9t%C3%A9o", phrases: ["meteo", "temps dehors", "quel temps", "temps fait"] },
  { id: "traduction", title: "Traduction", glyph: "translate", url: "https://translate.google.com", phrases: ["traduction", "traduire", "traducteur", "translate"] },
  { id: "spotify", title: "Spotify", glyph: "spotify", url: "https://open.spotify.com", phrases: ["spotify", "musique", "ecouter musique"] },
  { id: "disney", title: "Disney+", glyph: "castle", url: "https://www.disneyplus.com", phrases: ["disney", "disney plus"] },
  { id: "primevideo", title: "Prime Video", glyph: "television", url: "https://www.primevideo.com", phrases: ["prime video", "amazon prime"] },
  { id: "amazon", title: "Amazon", glyph: "cart", url: "https://www.amazon.ca", phrases: ["amazon", "magasiner"] }
]

// Diva's own settings, findable by name. `page` opens a page of her menu,
// `run` is a fixed argv.
var SETTINGS = [
  { id: "settings", title: "Réglages de Diva", glyph: "cog", page: "settings",
    phrases: ["reglages", "parametres", "preferences", "options", "configuration", "reglages diva"] },
  { id: "name", title: "Mon prénom", glyph: "account", page: "settings",
    phrases: ["prenom", "mon prenom", "changer prenom", "mon nom"] },
  { id: "assistant", title: "Mon assistante", glyph: "creation", page: "settings",
    phrases: ["assistante", "assistant", "ia", "intelligence artificielle", "claude", "compte claude", "connexion claude"] },
  { id: "animations", title: "Animations", glyph: "sparkles", page: "settings", phrases: ["animations", "animation"] },
  { id: "wallpaper-pick", title: "Choisir un fond d'écran", glyph: "images", run: ["omarchy-theme-bg-switcher"],
    phrases: ["fond ecran", "fond", "choisir fond", "arriere plan", "wallpaper", "image fond"] },
  { id: "extensions", title: "Extensions", glyph: "puzzle", page: "plugins",
    phrases: ["extensions", "extension", "plugins", "plugin", "modules", "boutique"] }
]

// French words she might use for the settings Omarchy names in English.
var FRENCH = {
  apparence: ["style"], applications: ["apps", "package", "webapp"], appli: ["apps", "webapp"], audio: ["audio"],
  barre: ["bar"], batterie: ["battery"], capture: ["capture", "screenshot"], clavier: ["keyboard", "input", "keybindings"],
  couleur: ["theme", "color"], couleurs: ["theme", "color"], date: ["time", "timezone"], deconnexion: ["logout"],
  defaut: ["default", "defaults"], desinstaller: ["remove"], dictee: ["dictation"], ecran: ["monitors", "display", "screensaver"],
  editeur: ["editor"], empreinte: ["fingerprint"], enlever: ["remove"], enregistrer: ["screenrecord"],
  espaces: ["workspace"], eteindre: ["shutdown"], fenetres: ["window", "windows"], fond: ["background"],
  fuseau: ["timezone"], heure: ["time", "timezone"], horaire: ["timezone"], installer: ["install"],
  installation: ["install"], jeux: ["gaming"], jour: ["update"], langue: ["input"], luminosite: ["display", "nightlight"],
  maj: ["update"], mise: ["update"], mettre: ["update"], moniteur: ["monitors"], mot: ["password"],
  navigateur: ["browser"], nuit: ["nightlight"], partage: ["share"], partager: ["share"], passe: ["password"],
  pave: ["touchpad", "trackpad"], police: ["font"], polices: ["font"], propos: ["about"], raccourcis: ["keybindings"],
  rappel: ["reminder"], rappels: ["reminder"], redemarrer: ["reboot", "restart"], reglages: ["setup"],
  parametres: ["setup"], reseau: ["network"], securite: ["security"], son: ["audio"], souris: ["input"],
  supprimer: ["remove"], systeme: ["system"], tactile: ["touchpad", "touchscreen", "trackpad"], theme: ["theme"],
  themes: ["theme"], transparence: ["transparency"], veille: ["screensaver", "suspend"], verrouillage: ["lock", "unlock"],
  vitesse: ["speed"]
}

var SEARCH_VERBS = ["cherche", "chercher", "recherche", "rechercher", "trouve", "trouver", "google", "googler"]
var DAYS = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
var MONTHS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre",
              "novembre", "décembre"]

function clampPercent(n) {
  n = Math.round(Number(n))
  return isNaN(n) ? -1 : Math.max(0, Math.min(100, n))
}

function httpsUrl(url) {
  url = String(url || "").trim()
  return /^https:\/\/[a-z0-9.-]+\.[a-z]{2,}(\/[^\s"'<>\\]*)?$/i.test(url) ? url : ""
}

function host(url) {
  var m = /^https:\/\/([^\/]+)/i.exec(url)
  return m ? m[1].replace(/^www\./, "") : url
}

// ---------------------------------------------------------------- tiles

function levelTile(what, percent) {
  return what === "volume"
    ? { kind: "volume", id: "volume-" + percent, title: "Volume à " + percent + " %", glyph: "volume-high", icon: "", percent: percent, score: 120 }
    : { kind: "brightness", id: "brightness-" + percent, title: "Luminosité à " + percent + " %", glyph: "sun", icon: "", percent: percent, score: 120 }
}

function searchTile(text) {
  var shown = text.length > 28 ? text.slice(0, 27) + "…" : text
  return { kind: "search", id: "search", title: "Chercher « " + shown + " »", glyph: "magnify", icon: "", query: text, score: 20 }
}

function urlTile(url, title, glyph) {
  return { kind: "url", id: "url:" + url, title: title || host(url), glyph: glyph || "link", icon: "", url: url, score: 90 }
}

function aiTile() {
  return { kind: "ai", id: "ai", title: "Demander à Diva", glyph: "creation", icon: "", score: 25 }
}

// One place to watch films: the installed app when there is one, otherwise
// an offer to install it the official way.
function movieTile(movie, apps, value) {
  var wanted = Actions.words(movie.title).join(" ")
  for (var i = 0; i < apps.length; i++) {
    if ((movie.flatpak && apps[i].id === movie.flatpak) || Actions.words(apps[i].name).join(" ") === wanted)
      return { kind: "app", id: apps[i].id, title: movie.title, glyph: "", icon: apps[i].icon, score: value }
  }
  return { kind: "install", id: movie.id, title: "Installer " + movie.title, glyph: movie.glyph, icon: "", score: value,
           caption: movie.flatpak ? "Application officielle" : "Application web",
           confirm: "Installer " + movie.title + " ? Clique encore pour confirmer." }
}

function movieTiles(apps) {
  return MOVIES.map(function(m, i) { return movieTile(m, apps, 100 - i) })
}

// ------------------------------------------------------------- parsing

// "volume à 40", "mets le son à 30 %", "luminosité au max", "son à moitié".
function parseLevel(query) {
  var w = Actions.words(query)
  var what = ""
  for (var i = 0; i < w.length; i++) {
    if (w[i] === "volume" || w[i] === "son") what = "volume"
    else if (w[i].indexOf("luminosit") === 0 || w[i] === "ecran") what = what || "brightness"
  }
  if (!what) return null
  var percent = -1
  for (var k = 0; k < w.length; k++) {
    if (/^\d{1,3}$/.test(w[k])) percent = clampPercent(w[k])
    // "à fond" is full blast; "fond d'écran" is a wallpaper.
    else if (w[k] === "max" || w[k] === "maximum" || (w[k] === "fond" && w[k - 1] === "a")) percent = 100
    else if (w[k] === "moitie") percent = 50
  }
  return percent < 0 ? null : levelTile(what, percent)
}

// A small arithmetic evaluator (no eval): + - * / ( ) and "x", "×", "÷", with
// a comma or a dot as the decimal mark. Returns null for anything else.
function calculate(text) {
  var src = String(text || "").replace(/\s+/g, "").replace(/[x×]/gi, "*").replace(/÷/g, "/").replace(/,/g, ".")
  if (!/^[0-9+\-*\/().]+$/.test(src) || !/[+\-*\/]/.test(src.slice(1)) || !/\d/.test(src)) return null
  var pos = 0
  function number() {
    var m = /^\d+(\.\d+)?/.exec(src.slice(pos))
    if (!m) throw new Error("number")
    pos += m[0].length
    return parseFloat(m[0])
  }
  function factor() {
    if (src.charAt(pos) === "-") { pos++; return -factor() }
    if (src.charAt(pos) === "+") { pos++; return factor() }
    if (src.charAt(pos) === "(") {
      pos++
      var v = sum()
      if (src.charAt(pos) !== ")") throw new Error("paren")
      pos++
      return v
    }
    return number()
  }
  function product() {
    var v = factor()
    while (src.charAt(pos) === "*" || src.charAt(pos) === "/") {
      var op = src.charAt(pos++)
      var r = factor()
      v = op === "*" ? v * r : v / r
    }
    return v
  }
  function sum() {
    var v = product()
    while (src.charAt(pos) === "+" || src.charAt(pos) === "-") {
      var op = src.charAt(pos++)
      var r = product()
      v = op === "+" ? v + r : v - r
    }
    return v
  }
  try {
    var result = sum()
    if (pos !== src.length || !isFinite(result)) return null
    return String(Math.round(result * 1e6) / 1e6).replace(".", ",")
  } catch (e) {
    return null
  }
}

// "rappelle-moi dans 10 minutes de sortir le gâteau", "minuteur 5 min".
// The message stays her own words and travels as one argument.
function parseReminder(query) {
  var raw = String(query || "").trim()
  var w = Actions.words(raw)
  var asked = false
  for (var i = 0; i < w.length; i++)
    if (w[i].indexOf("rappel") === 0 || w[i] === "minuteur" || w[i] === "previens" || w[i] === "timer") asked = true
  if (!asked) return null
  var m = /(\d{1,4})\s*(minutes?|min|mn|heures?|h)(?![a-zà-ÿ])\s*(.*)$/i.exec(raw)
  if (!m) return null
  var minutes = parseInt(m[1]) * (/^h/i.test(m[2]) ? 60 : 1)
  if (!(minutes >= 1 && minutes <= 1440)) return null
  var text = m[3].replace(/^(de|d'|d’|que|pour|:)\s*/i, "").replace(/[.!?\s]+$/, "").trim()
  var when = minutes % 60 === 0 ? (minutes / 60) + " h" : minutes + " min"
  return { kind: "reminder", id: "reminder", title: "Rappel dans " + when, caption: text || "Je te préviens", glyph: "clock",
           icon: "", minutes: minutes, text: text, score: 128 }
}

function two(n) { return n < 10 ? "0" + n : String(n) }

// Questions Diva answers herself, in a sentence.
function answer(query, now, state) {
  var w = Actions.words(query)
  if (w.length === 0 || w.length > 6) return ""
  if (state && state.battery >= 0 && (w.indexOf("batterie") >= 0 || w.indexOf("pile") >= 0))
    return "Il te reste " + state.battery + " % de batterie" + (state.charging ? ", et elle se recharge." : ".")
  if (w.indexOf("heure") >= 0) return "Il est " + now.getHours() + " h " + two(now.getMinutes()) + "."
  if (w.indexOf("jour") >= 0 || w.indexOf("date") >= 0)
    return "On est " + DAYS[now.getDay()] + " " + now.getDate() + " " + MONTHS[now.getMonth()] + " " + now.getFullYear() + "."
  return ""
}

// "cherche une recette de crêpes" -> "une recette de crêpes"; "" when the
// request does not start with a search word.
function searchText(query) {
  var raw = String(query || "").trim()
  var first = Actions.words(raw.split(/\s+/)[0] || "")[0] || ""
  if (SEARCH_VERBS.indexOf(first) < 0) return ""
  return raw.replace(/^\S+\s*/, "").trim()
}

function learnedKey(query) {
  return Actions.tokens(query).join(" ")
}

// ------------------------------------------------- Omarchy's own menu

// JSONC -> JSON text: drops // and /* */ comments and trailing commas,
// leaving anything inside a string alone.
function stripJsonc(text) {
  var out = "", inString = false
  text = String(text || "")
  for (var i = 0; i < text.length; i++) {
    var c = text.charAt(i), next = text.charAt(i + 1)
    if (inString) {
      out += c
      if (c === "\\") { out += next; i++ }
      else if (c === '"') inString = false
    } else if (c === '"') {
      inString = true
      out += c
    } else if (c === "/" && next === "/") {
      while (i < text.length && text.charAt(i) !== "\n") i++
      out += "\n"
    } else if (c === "/" && next === "*") {
      i = text.indexOf("*/", i + 2)
      if (i < 0) break
      i++
    } else {
      out += c
    }
  }
  return out.replace(/,(\s*[}\]])/g, "$1")
}

// Every entry of Omarchy's menu definition(s), commands and submenus, as
// { id, label, path } with `path` the labels of its parents. Later texts
// override earlier ones, the way the user's extension file does.
function parseCommands(texts) {
  var entries = {}
  for (var t = 0; t < texts.length; t++) {
    var parsed = null
    try { parsed = JSON.parse(stripJsonc(texts[t])) } catch (e) { parsed = null }
    if (!parsed || typeof parsed !== "object") continue
    for (var id in parsed) {
      if (!parsed[id] || typeof parsed[id] !== "object") continue
      var merged = entries[id] || {}
      for (var k in parsed[id]) merged[k] = parsed[id][k]
      entries[id] = merged
    }
  }
  var out = []
  for (var key in entries) {
    var e = entries[key]
    // Entries without an action are submenus (Style › Font); summoning one opens it.
    if (!e.label || !/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(key)) continue
    var parts = key.split("."), path = []
    for (var p = 1; p < parts.length; p++) {
      var parent = entries[parts.slice(0, p).join(".")]
      if (parent && parent.label) path.push(String(parent.label))
    }
    out.push({ id: key, label: String(e.label), path: path.join(" › ") })
  }
  return out
}

// A typed word, plus what it means in Omarchy's English when it is French.
function meanings(word) {
  return [word].concat(FRENCH[word] || [])
}

// The best `Actions.loose` match of any candidate against any word, 0..1.
function startsAny(hay, candidates) {
  var best = 0
  for (var c = 0; c < candidates.length; c++)
    for (var j = 0; j < hay.length; j++) {
      var q = Actions.loose(candidates[c], hay[j])
      if (q > best) best = q
    }
  return best
}

// Omarchy commands whose label, parents or id contain every typed word, in
// English or through its French meaning.
function matchCommands(typed, commands, limit) {
  var out = []
  for (var i = 0; i < commands.length; i++) {
    var c = commands[i]
    var hay = Actions.words(c.label + " " + c.path + " " + c.id)
    var label = Actions.words(c.label)
    var quality = 1, inLabel = 0
    for (var k = 0; k < typed.length && quality > 0; k++) {
      var candidates = meanings(typed[k])
      quality = Math.min(quality, startsAny(hay, candidates))
      if (quality > 0 && startsAny(label, candidates) === 1) inLabel++
    }
    if (quality > 0)
      out.push({ kind: "omarchy", id: c.id, title: c.label, caption: c.path || "Omarchy", glyph: "cog", icon: "",
                 // A word found in the label itself counts most; then the nearest to the root;
                 // a fuzzy match ranks under an exact one.
                 score: (30 + inLabel * 3 - (c.id.split(".").length - 1) * 0.5) * quality })
  }
  out.sort(function(a, b) { return b.score - a.score || a.title.localeCompare(b.title) })
  return out.slice(0, limit)
}

function matchSettings(query) {
  var out = []
  for (var i = 0; i < SETTINGS.length; i++) {
    var value = Actions.phraseScore(query, SETTINGS[i].phrases)
    if (value > 0)
      out.push({ kind: "setting", id: SETTINGS[i].id, title: SETTINGS[i].title, caption: "Réglage", glyph: SETTINGS[i].glyph,
                 icon: "", page: SETTINGS[i].page || "", score: value - 8 })
  }
  return out
}

// ----------------------------------------------------------- navigation

// What Diva can do to the window she was called from. `op` is a fixed word
// bin/diva-window knows; `stay` keeps the menu open to press again.
var WINDOW_ACTIONS = [
  { id: "close", title: "Fermer la fenêtre", glyph: "window-close",
    phrases: ["fermer fenetre", "ferme fenetre", "fermer", "ferme", "quitter application", "fermer application"] },
  { id: "fullscreen", title: "Plein écran", glyph: "fullscreen",
    phrases: ["plein ecran", "fenetre plein ecran", "mettre plein ecran", "sortir plein ecran", "quitter plein ecran"] },
  { id: "maximize", title: "Agrandir au maximum", glyph: "window-maximize",
    phrases: ["agrandir fenetre", "agrandir", "maximiser", "fenetre plus grande", "toute largeur"] },
  { id: "float", title: "Détacher ou ranger", glyph: "window-restore",
    phrases: ["fenetre flottante", "flottante", "detacher fenetre", "detacher", "ranger fenetre", "fenetre libre", "mosaique"] },
  { id: "wider", title: "Plus large", glyph: "expand", stay: true,
    phrases: ["plus large", "elargir", "elargir fenetre", "fenetre plus large", "redimensionner", "changer taille fenetre"] },
  { id: "narrower", title: "Moins large", glyph: "collapse", stay: true,
    phrases: ["moins large", "retrecir", "retrecir fenetre", "fenetre plus petite", "fenetre moins large", "redimensionner"] },
  { id: "left", title: "Mettre à gauche", glyph: "arrow-left-bold",
    phrases: ["mettre gauche", "fenetre gauche", "deplacer gauche", "a gauche", "deplacer fenetre"] },
  { id: "right", title: "Mettre à droite", glyph: "arrow-right-bold",
    phrases: ["mettre droite", "fenetre droite", "deplacer droite", "a droite", "deplacer fenetre"] },
  { id: "split", title: "Changer le partage", glyph: "swap",
    phrases: ["changer partage", "cote a cote", "empiler fenetres", "fenetres haut bas", "inverser fenetres"] },
  { id: "next", title: "Fenêtre suivante", glyph: "layers",
    phrases: ["fenetre suivante", "autre fenetre", "passer fenetre suivante", "changer fenetre"] },
  { id: "pop", title: "Garder au premier plan", glyph: "pin",
    phrases: ["premier plan", "garder dessus", "epingler fenetre", "toujours visible", "au dessus"] }
]

// How to get around, said in her words. {Description} is replaced by the key
// this computer really binds to that Omarchy action (see parseBindings); the
// text after "|" is used when it has none.
var GUIDE = [
  { id: "close", title: "Fermer une fenêtre", glyph: "window-close", phrases: ["fermer fenetre", "comment fermer", "quitter application"],
    text: "{Close window|Super + W} ferme la fenêtre où tu es. Tu peux aussi me dire « ferme la fenêtre »." },
  { id: "move", title: "Déplacer une fenêtre", glyph: "mouse", phrases: ["deplacer fenetre", "bouger fenetre", "comment deplacer", "changer fenetre place"],
    text: "Garde Super enfoncé et fais glisser la fenêtre avec le clic gauche. Au clavier, {Swap window to the left|Super + Maj + ←} et {Swap window to the right|Super + Maj + →} l'échangent avec sa voisine." },
  { id: "resize", title: "Changer la taille d'une fenêtre", glyph: "expand", phrases: ["taille fenetre", "changer taille fenetre", "redimensionner", "redimensionner fenetre", "agrandir fenetre", "retrecir fenetre", "changer taille"],
    text: "Garde Super enfoncé et fais glisser avec le clic droit, ou attrape le bord de la fenêtre. Au clavier : {Shrink window left|Super + =} et {Expand window left|Super + -}." },
  { id: "fullscreen", title: "Plein écran", glyph: "fullscreen", phrases: ["plein ecran", "comment plein ecran", "sortir plein ecran"],
    text: "{Full screen|Super + F} met la fenêtre en plein écran. La même touche la remet comme avant." },
  { id: "float", title: "Fenêtres rangées ou détachées", glyph: "window-restore", phrases: ["fenetre flottante", "detacher fenetre", "fenetres rangees", "mosaique", "pourquoi fenetres cote"],
    text: "Ici les fenêtres se rangent toutes seules côte à côte. {Toggle window floating/tiling|Super + T} en détache une pour la poser où tu veux, et la même touche la range." },
  { id: "switch", title: "Passer d'une fenêtre à l'autre", glyph: "layers", phrases: ["changer fenetre", "passer fenetre", "autre fenetre", "retrouver fenetre", "ou est fenetre", "fenetre disparu"],
    text: "{Focus on next window|Alt + Tab} passe à la fenêtre suivante, et Super avec une flèche va vers celle d'à côté. Sinon ouvre « Mes fenêtres » ici, ou tape le nom de l'application." },
  { id: "workspaces", title: "Les espaces de travail", glyph: "grid", phrases: ["espaces", "espace travail", "bureaux", "changer espace", "changer bureau", "c est quoi espaces"],
    text: "Les espaces sont comme plusieurs bureaux, numérotés en haut de l'écran. {Switch to workspace 2|Super + 2} va sur le deuxième (n'importe quel chiffre marche), {Move window to workspace 2|Super + Maj + 2} y envoie la fenêtre, et trois doigts glissés sur le pavé passent de l'un à l'autre." },
  { id: "trackpad", title: "Le pavé tactile", glyph: "gesture", phrases: ["pave tactile", "trackpad", "touchpad", "gestes", "clic droit pave", "defiler"],
    text: "Deux doigts pour faire défiler, un petit tapotement pour cliquer, deux doigts tapotés pour le clic droit, et trois doigts glissés sur le côté pour changer d'espace." },
  { id: "mouse", title: "La souris", glyph: "mouse", phrases: ["souris", "actions souris", "clic droit", "molette"],
    text: "Super + clic gauche déplace une fenêtre, Super + clic droit change sa taille, et Super avec la molette change d'espace. Tu peux aussi attraper le bord d'une fenêtre." },
  { id: "copy", title: "Copier et coller", glyph: "file", phrases: ["copier coller", "copier", "coller", "couper", "comment copier"],
    text: "{Universal copy|Super + C} copie, {Universal paste|Super + V} colle et {Universal cut|Super + X} coupe, partout." },
  { id: "screenshot", title: "Capture d'écran", glyph: "image", phrases: ["capture ecran", "screenshot", "photo ecran", "impr ecran"],
    text: "{Screenshot|Impr écran} prend une capture : choisis la zone, elle va dans tes photos." },
  { id: "lock", title: "Verrouiller l'ordinateur", glyph: "lock", phrases: ["verrouiller raccourci", "comment verrouiller"],
    text: "{Lock system|Super + Ctrl + L} verrouille l'ordinateur. Je peux aussi le faire pour toi." },
  { id: "diva", title: "M'appeler", glyph: "heart", phrases: ["ouvrir diva", "appeler diva", "comment ouvrir menu", "raccourci diva"],
    text: "{Diva|Super + Espace} m'ouvre, de n'importe où. Je suis aussi dans la barre en haut et dans le coin du bureau." },
  { id: "keys", title: "Tous les raccourcis", glyph: "keyboard", phrases: ["raccourcis", "raccourcis clavier", "touches", "liste raccourcis", "aide clavier"],
    text: "{Keybindings|Super + K} ouvre la liste complète des raccourcis d'Omarchy (en anglais).", run: ["omarchy-menu-keybindings"] }
]

var KEY_NAMES = { SUPER: "Super", SHIFT: "Maj", CTRL: "Ctrl", ALT: "Alt", TAB: "Tab", SPACE: "Espace", PRINT: "Impr écran",
                  LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓", MINUS: "-", EQUAL: "=", RETURN: "Entrée", ESCAPE: "Échap",
                  DELETE: "Suppr", HOME: "Début", "LEFT MOUSE BUTTON": "clic gauche", "RIGHT MOUSE BUTTON": "clic droit",
                  mouse_down: "molette vers le bas", mouse_up: "molette vers le haut" }

// "SUPER SHIFT + LEFT" -> "Super + Maj + ←".
function keyLabel(keys) {
  var parts = String(keys || "").split(" + ")
  var last = parts.pop()
  var out = []
  var mods = parts.join(" ").split(/\s+/).filter(function(m) { return m.length > 0 })
  for (var i = 0; i < mods.length; i++) out.push(KEY_NAMES[mods[i]] || mods[i])
  out.push(KEY_NAMES[last.trim()] || last.trim())
  return out.join(" + ")
}

// The output of `omarchy menu keybindings --print` ("KEYS  →  Description"
// per line) as { description: keys }; the first binding of an action wins.
function parseBindings(text) {
  var map = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var at = lines[i].indexOf("→")
    if (at < 0) continue
    var keys = lines[i].slice(0, at).replace(/\s+/g, " ").trim()
    var what = lines[i].slice(at + 1).trim()
    if (keys && what && map[what] === undefined) map[what] = keys
  }
  return map
}

function guideText(topic, bindings) {
  return topic.text.replace(/\{([^|}]+)\|([^}]*)\}/g, function(all, what, fallback) {
    return bindings && bindings[what] ? keyLabel(bindings[what]) : fallback
  })
}

// Everything in the guide as plain lines, for the assistant to rely on.
function guideLines(bindings) {
  return GUIDE.map(function(t) { return "- " + t.title + " : " + guideText(t, bindings) }).join("\n")
}

function helpTile(topic, bindings, value) {
  return { kind: "help", id: topic.id, title: topic.title, caption: "Astuce", glyph: "lightbulb", icon: "",
           text: guideText(topic, bindings), score: value }
}

function windowActionTile(action, value, number) {
  var tile = { kind: "winact", id: action.id, title: action.title, caption: "Cette fenêtre", glyph: action.glyph, icon: "",
               stay: action.stay === true, score: value }
  if (number) tile.number = number
  return tile
}

// "brave-browser" -> "Brave Browser", "org.gnome.Nautilus" -> "Nautilus".
function appName(cls) {
  var last = String(cls || "").split(".").pop().replace(/[-_]+/g, " ").trim()
  return last.replace(/(^|\s)([a-zà-ÿ])/g, function(all, space, letter) { return space + letter.toUpperCase() }) || "Fenêtre"
}

function windowTile(w, value) {
  return { kind: "window", id: w.address, title: appName(w.cls), caption: w.title || ("Espace " + w.workspace), glyph: "application",
           icon: w.icon || "", score: value }
}

// Open windows whose application or title contains every typed word.
function matchWindows(query, windows, limit) {
  var q = Actions.tokens(query)
  if (!q.length) return []
  var out = []
  for (var i = 0; i < windows.length; i++) {
    var hay = Actions.words(windows[i].cls + " " + windows[i].title)
    var quality = 1
    for (var k = 0; k < q.length && quality > 0; k++) {
      var hit = 0
      for (var j = 0; j < hay.length; j++) hit = Math.max(hit, Actions.loose(q[k], hay[j]))
      quality = Math.min(quality, hit)
    }
    if (quality > 0) out.push(windowTile(windows[i], Math.round(96 * quality)))
  }
  out.sort(function(a, b) { return b.score - a.score })
  return out.slice(0, limit)
}

// "envoie la fenêtre sur l'espace 2", "va sur le bureau 3", "espace 4".
function parseWorkspace(query) {
  var w = Actions.words(query)
  var place = -1
  for (var i = 0; i < w.length; i++) if (w[i] === "espace" || w[i] === "bureau") place = i
  if (place < 0 || !/^([1-9]|10)$/.test(w[place + 1] || "")) return null
  var number = parseInt(w[place + 1])
  var send = w.some(function(x) { return x.indexOf("envoy") === 0 || x.indexOf("envoi") === 0 || x.indexOf("deplac") === 0 || x === "fenetre" })
  return send
    ? { kind: "winact", id: "to-workspace", number: number, title: "Envoyer sur l'espace " + number, caption: "Cette fenêtre", glyph: "arrow-right", icon: "", score: 122 }
    : { kind: "winact", id: "goto-workspace", number: number, title: "Aller à l'espace " + number, caption: "", glyph: "grid", icon: "", score: 122 }
}

// "Mes fenêtres": what is open, then what she can do to the one she was in.
function windowTiles(windows) {
  var out = []
  for (var i = 0; i < windows.length && i < 12; i++) out.push(windowTile(windows[i], 200 - i))
  var core = ["close", "fullscreen", "float", "wider", "narrower", "left", "right", "next"]
  for (var c = 0; c < core.length; c++)
    for (var a = 0; a < WINDOW_ACTIONS.length; a++)
      if (WINDOW_ACTIONS[a].id === core[c]) out.push(windowActionTile(WINDOW_ACTIONS[a], 100 - c))
  return out
}

// ------------------------------------------------------------- intents

// An intent is what the AI assistant (or a learned shortcut) asks for. Only
// these shapes exist, and each is checked against what Diva really has; an
// unknown action, a missing app or a non-https address gives null.
function intentTile(intent, apps) {
  if (!intent) return null
  var type = String(intent.type || "")
  if (type === "action") {
    var action = Actions.byId(String(intent.id || ""))
    return action ? Actions.tile(action, 110) : null
  }
  if (type === "app") {
    var wanted = Actions.words(intent.name).join(" ")
    if (!wanted) return null
    for (var i = 0; i < apps.length; i++)
      if (Actions.words(apps[i].name).join(" ") === wanted)
        return { kind: "app", id: apps[i].id, title: apps[i].name, glyph: "", icon: apps[i].icon, score: 110 }
    var close = Actions.matchApps(String(intent.name), apps, 1)
    return close.length ? close[0] : null
  }
  if (type === "url") {
    var url = httpsUrl(intent.url)
    return url ? urlTile(url) : null
  }
  if (type === "search") {
    var text = String(intent.query || "").trim()
    return text ? searchTile(text) : null
  }
  if (type === "volume" || type === "brightness") {
    var percent = clampPercent(intent.percent)
    return percent < 0 ? null : levelTile(type, percent)
  }
  return null
}

// The intent to remember for a tile, so the same words work next time
// without the assistant. Searches are not remembered: their words are the
// request itself.
function tileIntent(tile) {
  if (tile.kind === "action") return { type: "action", id: tile.id }
  if (tile.kind === "app") return { type: "app", name: tile.title }
  if (tile.kind === "url") return { type: "url", url: tile.url }
  if (tile.kind === "volume" || tile.kind === "brightness") return { type: tile.kind, percent: tile.percent }
  return null
}

// Whether this reads as something to talk about rather than a thing to open:
// it ends with a question mark, starts like a question, or is a whole sentence.
var ASKING = ["comment", "pourquoi", "quoi", "quel", "quelle", "quels", "quelles", "combien", "qui", "quand", "qu",
              "c", "est", "peux", "pourrais", "sais", "connais", "explique", "raconte", "dis", "conseille", "penses"]

function looksLikeQuestion(query) {
  var raw = String(query || "").trim()
  if (/\?\s*$/.test(raw)) return true
  var w = Actions.words(raw)
  if (w.length >= 3 && ASKING.indexOf(w[0]) >= 0) return true
  return w.length >= 6
}

// ------------------------------------------------------------- resolve

// Everything Diva offers for a request, best first, plus a spoken `answer`
// when she can simply reply.
// ctx: { apps, learned, aiEnabled, now, commands, showCommands, group, state,
//        windows, bindings }.
function resolve(query, ctx) {
  var apps = ctx.apps || []
  var commands = ctx.commands || []
  // ">" asks for Omarchy's own commands and nothing else.
  var advanced = /^\s*>/.test(String(query))
  if (advanced) {
    var typed = Actions.words(String(query).replace(/^\s*>/, ""))
    return { tiles: matchCommands(typed, commands, typed.length ? 15 : 0), answer: "" }
  }
  if (Actions.words(query).length === 0)
    return { tiles: ctx.group === "movie" ? movieTiles(apps) : ctx.group === "windows" ? windowTiles(ctx.windows || []) : Actions.home(),
             answer: "" }

  var tiles = []
  var seen = {}
  function add(tile) {
    var key = tile.kind + ":" + tile.id
    if (seen[key]) return
    seen[key] = true
    tiles.push(tile)
  }

  var key = learnedKey(query)
  var learned = ctx.learned || []
  for (var l = 0; l < learned.length; l++) {
    if (learned[l].key !== key || !key) continue
    var known = intentTile(learned[l].intent, apps)
    if (known) { known.score = 130; known.learned = true; add(known) }
  }

  var reminder = parseReminder(query)
  if (reminder) add(reminder)

  var level = reminder ? null : parseLevel(query)
  if (level) add(level)

  var result = calculate(query)
  if (result !== null)
    add({ kind: "calc", id: "calc", title: "= " + result, glyph: "calculator", icon: "", text: result, score: 125 })

  var guided = ""
  var wanted = searchText(query)
  if (wanted) {
    var explicit = searchTile(wanted)
    explicit.score = 115
    add(explicit)
  } else {
    var place = parseWorkspace(query)
    if (place) add(place)
    var found = Actions.match(query)
    for (var a = 0; a < found.length; a++) add(found[a])
    // Windows that are already open come before opening the app again.
    var open = matchWindows(query, ctx.windows || [], 6)
    for (var w = 0; w < open.length; w++) add(open[w])
    for (var n = 0; n < WINDOW_ACTIONS.length; n++) {
      var does = Actions.phraseScore(query, WINDOW_ACTIONS[n].phrases)
      if (does > 0) add(windowActionTile(WINDOW_ACTIONS[n], does - 1))
    }
    for (var g = 0; g < GUIDE.length; g++) {
      var helps = Actions.phraseScore(query, GUIDE[g].phrases)
      if (helps > 0) {
        var tip = helpTile(GUIDE[g], ctx.bindings, helps - 4)
        add(tip)
        // "comment je ferme une fenêtre ?" is answered outright.
        if (!guided && looksLikeQuestion(query)) guided = tip.text
      }
    }
    for (var v = 0; v < MOVIES.length; v++) {
      var watch = Actions.phraseScore(query, MOVIES[v].phrases)
      if (watch > 0) add(movieTile(MOVIES[v], apps, watch - 2))
    }
    for (var s = 0; s < SITES.length; s++) {
      var value = Actions.phraseScore(query, SITES[s].phrases)
      if (value > 0) {
        var site = urlTile(SITES[s].url, SITES[s].title, SITES[s].glyph)
        site.score = value - 5
        add(site)
      }
    }
    var own = matchSettings(query)
    for (var o = 0; o < own.length; o++) add(own[o])
    var matched = Actions.matchApps(query, apps, 10)
    for (var m = 0; m < matched.length; m++) {
      // An installed app already offered as a place to watch films is not listed twice.
      if (!seen["app:" + matched[m].id]) add(matched[m])
    }
  }

  // Omarchy's settings and commands sit quietly after everything Diva offers herself.
  if (ctx.showCommands && !wanted && result === null && Actions.tokens(query).join("").length >= 3) {
    var extra = matchCommands(Actions.tokens(query), commands, 4)
    for (var c = 0; c < extra.length; c++) add(extra[c])
  }

  tiles.sort(function(x, y) { return y.score - x.score })
  var said = tiles.length === 0 || result === null ? answer(query, ctx.now || new Date(), ctx.state) : ""
  if (said === "" && guided) said = guided

  // Always a way forward: her assistant when it is set up, and the web. A
  // question goes to the assistant first, unless Diva already has the exact
  // answer herself.
  if (result === null && Actions.tokens(query).length > 0) {
    if (ctx.aiEnabled) {
      var ask = aiTile()
      if (!wanted && said === "" && looksLikeQuestion(query) && (tiles.length === 0 || tiles[0].score < 100)) {
        ask.score = 200
        tiles.unshift(ask)
        seen["ai:ai"] = true
      } else {
        add(ask)
      }
    }
    if (!wanted) add(searchTile(String(query).trim()))
  }
  return { tiles: tiles.slice(0, 15), answer: said }
}

// ---------------------------------------------------------------- layout

// Where each kind of result is shown, and how: every section has its own
// look, so what a result does can be told at a glance.
//   answer    something Diva tells her (a tip, a sum)
//   windows   open windows, as cards with a live preview
//   window    what can be done to the window she was in, as pills
//   do        things Diva does right now (sound, light, a reminder), as wide buttons
//   open      applications and sites, as app icons
//   settings  Diva's and Omarchy's settings, as list rows
//   ask       her assistant and the web, as bars
var SECTIONS = [
  { id: "answer", title: "", kinds: ["help", "calc"] },
  { id: "windows", title: "Fenêtres ouvertes", kinds: ["window"] },
  { id: "window", title: "Cette fenêtre", kinds: ["winact"] },
  { id: "do", title: "Faire", kinds: ["action", "volume", "brightness", "reminder"] },
  { id: "open", title: "Ouvrir", kinds: ["app", "url", "install"] },
  { id: "settings", title: "Réglages", kinds: ["setting", "omarchy"] },
  { id: "ask", title: "Demander ou chercher", kinds: ["ai", "search"] }
]

// Tiles (best first) arranged into sections. The most relevant section comes
// first, answers always lead and "ask" closes unless the assistant is the
// best answer. `flat` is every tile in display order, each knowing its index
// (`flat`), and `best` is where the best tile ended up: Enter runs that one.
function layout(tiles) {
  var sections = []
  for (var s = 0; s < SECTIONS.length; s++) {
    var mine = tiles.filter(function(t) { return SECTIONS[s].kinds.indexOf(t.kind) >= 0 })
    if (mine.length)
      sections.push({ id: SECTIONS[s].id, title: SECTIONS[s].title, tiles: mine, order: s,
                      top: Math.max.apply(null, mine.map(function(t) { return t.score || 0 })) })
  }
  function rank(sec) {
    if (sec.id === "answer") return 1e6
    if (sec.id === "ask") return sec.top >= 200 ? 1e5 : -1
    return sec.top
  }
  sections.sort(function(a, b) { return rank(b) - rank(a) || a.order - b.order })
  var flat = [], best = 0, top = -Infinity
  for (var i = 0; i < sections.length; i++)
    for (var j = 0; j < sections[i].tiles.length; j++) {
      var tile = sections[i].tiles[j]
      tile.flat = flat.length
      if ((tile.score || 0) > top && tile.kind !== "help") { top = tile.score || 0; best = flat.length }
      flat.push(tile)
    }
  return { sections: sections, flat: flat, best: best }
}

// The argv a tile runs; null for tiles that run nothing themselves (ai, a
// group, a page of the menu). `pluginDir` locates Diva's own helpers.
function argv(tile, config, dirs, pluginDir) {
  if (tile.kind === "action") return Actions.argv(Actions.byId(tile.id), config, dirs)
  // The launcher Omarchy's own app menu uses.
  if (tile.kind === "app") return ["uwsm-app", "--", "gtk-launch", tile.id + ".desktop"]
  if (tile.kind === "url") return httpsUrl(tile.url) ? ["omarchy-launch-browser", tile.url] : null
  if (tile.kind === "search") {
    var base = httpsUrl(String(config && config.searchUrl || "").replace(/[?&]q=$/, "")) ? String(config.searchUrl) : "https://www.google.com/search?q="
    return ["omarchy-launch-browser", base + encodeURIComponent(tile.query)]
  }
  if (tile.kind === "volume") return ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (clampPercent(tile.percent) / 100).toFixed(2)]
  if (tile.kind === "brightness") return ["omarchy-brightness-display", Math.max(1, clampPercent(tile.percent)) + "%"]
  if (tile.kind === "calc") return ["wl-copy", "--", String(tile.text)]
  if (tile.kind === "reminder") {
    var minutes = Math.round(Number(tile.minutes))
    return minutes >= 1 && minutes <= 1440 ? ["omarchy-reminder", String(minutes), String(tile.text || "Rappel")] : null
  }
  // Omarchy runs its own entry: conditions, confirmations and all.
  if (tile.kind === "omarchy") return /^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(tile.id) ? ["omarchy-menu", "summon", tile.id] : null
  if (tile.kind === "setting") {
    for (var i = 0; i < SETTINGS.length; i++) if (SETTINGS[i].id === tile.id) return SETTINGS[i].run ? SETTINGS[i].run.slice() : null
    return null
  }
  if (tile.kind === "window")
    return pluginDir && /^0x[0-9a-f]{4,16}$/.test(tile.id) ? [pluginDir + "/bin/diva-window", "focus", tile.id] : null
  if (tile.kind === "winact") {
    if (!pluginDir) return null
    if (tile.id === "to-workspace" || tile.id === "goto-workspace") {
      var number = Math.round(Number(tile.number))
      return number >= 1 && number <= 10 ? [pluginDir + "/bin/diva-window", tile.id, String(number)] : null
    }
    for (var w = 0; w < WINDOW_ACTIONS.length; w++)
      if (WINDOW_ACTIONS[w].id === tile.id)
        return WINDOW_ACTIONS[w].stay ? [pluginDir + "/bin/diva-window", tile.id, "--now"] : [pluginDir + "/bin/diva-window", tile.id]
    return null
  }
  if (tile.kind === "help") {
    for (var h = 0; h < GUIDE.length; h++) if (GUIDE[h].id === tile.id) return GUIDE[h].run ? GUIDE[h].run.slice() : null
    return null
  }
  if (tile.kind === "install") {
    for (var m = 0; m < MOVIES.length; m++)
      if (MOVIES[m].id === tile.id && pluginDir) return [pluginDir + "/bin/diva-install", tile.id]
    return null
  }
  return null
}

// What Diva says after running a tile, and whether her menu stays open.
function outcome(tile) {
  if (tile.kind === "action") {
    var action = Actions.byId(tile.id)
    return { reply: action.reply, stay: action.stay === true }
  }
  if (tile.kind === "volume" || tile.kind === "brightness") return { reply: "Voilà, " + tile.title.toLowerCase() + ".", stay: true }
  if (tile.kind === "calc") return { reply: "Copié : " + tile.text, stay: true }
  if (tile.kind === "winact") return { reply: tile.stay ? "Voilà. Encore ?" : "C'est fait.", stay: tile.stay === true }
  if (tile.kind === "reminder") return { reply: "C'est noté, je te préviens " + tile.title.replace("Rappel ", "") + ".", stay: true }
  return { reply: "C'est parti !", stay: false }
}
