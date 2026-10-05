.pragma library

// Diva's icons: named glyphs from the Material Design set in Omarchy's Nerd
// Font, so every button is one colour and one style. Checked against
// JetBrainsMono Nerd Font.
var MAP = {
  "account": "\u{F0004}", "arrow-left": "\u{F004D}", "bluetooth": "\u{F00AF}", "brightness": "\u{F00DF}",
  "calculator": "\u{F00EC}", "calendar": "\u{F00ED}", "cart": "\u{F0110}", "castle": "\u{F011A}",
  "check": "\u{F012C}", "clock": "\u{F0954}", "close": "\u{F0156}", "cog": "\u{F0493}",
  "creation": "\u{F0674}", "download": "\u{F01DA}", "facebook": "\u{F020C}", "file": "\u{F0219}",
  "flower": "\u{F024A}", "folder": "\u{F024B}", "gmail": "\u{F02AB}", "headphones": "\u{F02CB}",
  "heart": "\u{F02D1}", "image": "\u{F02E9}", "images": "\u{F02EF}", "instagram": "\u{F02FE}",
  "link": "\u{F0337}", "lock": "\u{F033E}", "magnify": "\u{F0349}", "map": "\u{F034D}",
  "messenger": "\u{F020E}", "movie": "\u{F0381}", "music": "\u{F075A}", "music-note": "\u{F0387}",
  "netflix": "\u{F0746}", "package": "\u{F03D3}", "palette": "\u{F03D8}", "pinterest": "\u{F0407}",
  "play": "\u{F040C}", "power": "\u{F0425}", "puzzle": "\u{F0431}", "restart": "\u{F0709}",
  "sparkles": "\u{F1545}", "spotify": "\u{F04C7}", "star": "\u{F04CE}", "sun": "\u{F05A8}",
  "television": "\u{F0502}", "translate": "\u{F05CA}", "update": "\u{F06B0}", "volume-high": "\u{F057E}",
  "volume-low": "\u{F0580}", "volume-off": "\u{F0581}", "wallpaper": "\u{F0E09}", "weather": "\u{F0595}",
  "moon": "\u{F0594}", "application": "\u{F08C6}", "windows": "\u{F10AC}", "window-close": "\u{F05AD}",
  "window-maximize": "\u{F05AF}", "window-restore": "\u{F05B2}", "fullscreen": "\u{F0293}", "expand": "\u{F084E}",
  "collapse": "\u{F084C}", "arrow-left-bold": "\u{F0731}", "arrow-right-bold": "\u{F0734}", "arrow-right": "\u{F0054}",
  "swap": "\u{F04E1}", "pin": "\u{F0403}", "layers": "\u{F0328}", "grid": "\u{F0570}", "keyboard": "\u{F030C}",
  "mouse": "\u{F037D}", "gesture": "\u{F0D76}", "help": "\u{F02D7}", "lightbulb": "\u{F0335}", "web": "\u{F059F}", "whatsapp": "\u{F05A3}", "wifi": "\u{F05A9}", "youtube": "\u{F05C3}"
}

function glyph(name) {
  return MAP[name] || MAP.heart
}
