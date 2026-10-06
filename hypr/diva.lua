-- Diva's look and feel for Hyprland, loaded after Omarchy's defaults and the
-- user's own hypr/*.lua. Aimed at someone coming from macOS: rounded, softly
-- translucent windows, natural scrolling, tap to click, a scrolling window ribbon and overview gestures.
-- Installed as ~/.config/hypr/diva.lua by bin/diva; remove the marked
-- require() line in hyprland.lua to switch all of it off.

hl.config({
  general = {
    layout = "scrolling",
    gaps_in = 6,
    gaps_out = 14,
    border_size = 2,
    -- The window you are not in gets a quiet plum rim instead of grey.
    col = { inactive_border = "rgba(6b526166)" },
    -- Drag a window's edge to resize it, as on macOS.
    resize_on_border = true,
  },

  decoration = {
    rounding = 14,

    -- The window you are not using steps back a little.
    dim_inactive = true,
    dim_strength = 0.05,

    shadow = {
      enabled = true,
      range = 22,
      render_power = 3,
      color = "rgba(120a12aa)",
    },

    -- Frosted glass behind translucent windows. Two cheap passes: the target
    -- laptop has integrated graphics. Set enabled = false if it feels slow.
    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      noise = 0.02,
      vibrancy = 0.15,
    },
  },

  scrolling = {
    column_width = 1.0,
    fullscreen_on_one_column = true,
    focus_fit_method = 1,
    follow_focus = true,
  },

  input = {
    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
      -- Two-finger click is a right click.
      clickfinger_behavior = true,
    },
  },
})

-- Slightly see-through windows. Omarchy tags every window "default-opacity"
-- and takes that tag off browsers and video apps, so films stay fully opaque.
o.window({ tag = "default-opacity" }, { opacity = "0.94 0.88" })

-- Diva's menu is frosted glass: blur what is behind her card, but not behind
-- the faint veil around it.
hl.layer_rule({ match = { namespace = "diva-menu" }, blur = true, ignore_alpha = 0.35 })
-- The overview is a sheet of the same glass over the whole screen.
hl.layer_rule({ match = { namespace = "diva-overview" }, blur = true, ignore_alpha = 0.35 })

-- The bar, notifications and Omarchy's own menus are translucent in the Diva
-- theme (theme/diva/shell.toml); blur what shows through them.
hl.layer_rule({
  match = { namespace = "^omarchy-(bar|notifications|osd|menu|clipboard|emojis|reminders|polkit)$" },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.3,
})

-- Motion, everywhere. Two curves: a spring that overshoots a touch, for
-- things arriving, and a soft ease for things leaving or gliding.
hl.curve("divaSpring", { type = "bezier", points = { { 0.34, 1.36 }, { 0.64, 1 } } })
hl.curve("divaSoft", { type = "bezier", points = { { 0.22, 0.9 }, { 0.3, 1 } } })

-- Windows pop in with a little bounce, shrink away, and glide when the
-- layout makes room for a new one.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.6, bezier = "divaSpring", style = "popin 78%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.8, bezier = "divaSoft", style = "popin 86%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.2, bezier = "divaSoft" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.6, bezier = "divaSoft" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.2, bezier = "divaSoft" })
-- Focus changes breathe: the rim and the dimming cross-fade.
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "divaSoft" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "divaSoft" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "divaSoft" })

-- Notifications, the volume display and reminders slide or pop in; Omarchy
-- keeps its bar and menus instant, and Diva's menu and desktop companion
-- animate themselves.
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.6, bezier = "divaSpring", style = "popin 88%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.4, bezier = "divaSoft", style = "fade" })
hl.layer_rule({ match = { namespace = "^omarchy-(notifications|reminders)$" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "^diva-(menu|companion|overview)$" }, no_anim = true })

-- Three fingers move along the window ribbon; workspaces are chosen in
-- Diva's overview. The scratchpad still drops in from above.
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.4, bezier = "divaSoft", style = "slidefade 18%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.6, bezier = "divaSpring", style = "slidevert" })
hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })

-- Cmd+Q habits: SUPER + Q closes the window, next to Omarchy's SUPER + W.
o.bind("SUPER + Q", "Fermer la fenêtre", hl.dsp.window.close())

-- Overview lives in Diva's service, independent of whether the menu is open.
hl.gesture({ fingers = 4, direction = "up", action = function()
  hl.exec_cmd("omarchy-shell diva.desktop show")
end })
hl.gesture({ fingers = 4, direction = "down", action = function()
  hl.exec_cmd("omarchy-shell diva.desktop hide")
end })
