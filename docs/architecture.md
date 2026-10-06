# Diva architecture note

Written against **Omarchy 4.0.4** on the test account (`testuser`, Dell Latitude 3410). Verified facts are separated from open questions; nothing here has been tried on the target EliteBook yet.

## Verified integration points

| Mechanism | What was verified | Where |
| --- | --- | --- |
| Shell plugins | A plugin is a git repo with `manifest.json` (`schemaVersion: 1`, `id`, `kinds`, `entryPoints`) cloned to `~/.config/omarchy/plugins/<id>/`. Kinds: `bar-widget`, `panel`, `overlay`, `menu`, `service`, `bar`. The `omarchy.*` id namespace is reserved. Plugins run unsandboxed inside `omarchy-shell`. | `/usr/share/omarchy/shell/README.md`, `omarchy plugin validate` |
| Plugin lifecycle | `omarchy plugin add <git-url> --enable --yes`, `update [id] --yes` (fast-forward pull, rolled back if validation fails), `remove`, `enable`, `disable`, `list --json`. The installer never runs plugin code or sudo. | `omarchy-plugin-*` source |
| Themes | A theme is a folder in `~/.config/omarchy/themes/<slug>/` with `colors.toml`; every app config is generated from it. `backgrounds/`, `icons.theme` and `preview.png` are optional. `omarchy theme set <slug>` applies it. | `omarchy-theme-set` source, stock themes |
| Hooks | `~/.config/omarchy/hooks/<event>.d/`: `post-update`, `post-boot`, `theme-set`, `font-set`, `battery-low`, `pre-refresh-pacman`. | `omarchy hook --help`, `omarchy-update` source |
| Overlay contract | An `overlay` entry point is an `Item` with `open(payloadJson)`, `close()` and an `opened` property; the shell injects `shell`, `manifest` and `omarchyPath`. `omarchy-shell shell toggle <id> '{}'` opens and closes it, `… call <id> <method> <arg>` calls a method on it. A plugin that is both `overlay` and `bar-widget` is owned by the panel loader. | `shell.qml`, first-party `emojis` plugin, tried with Diva |
| Applications | `DesktopEntries.applications` (Quickshell) lists installed apps; Omarchy launches them with `uwsm-app -- gtk-launch <id>.desktop`. | `services/AppLibrary.qml`, tried with Diva |
| Keybindings | `~/.config/hypr/bindings.lua` holds user bindings (`o.bind(keys, description, command)`); `hyprctl reload` then `hyprctl configerrors` validates them. A default binding is replaced with `hl.unbind(keys)` first. | Tried on this account |

## Architecture chosen for Phase 1

Diva is its own Omarchy shell plugin with its own menu. It does not depend on Keystroke or any other third-party plugin, and everything she reads is in French.

```
pack.json            what is in the pack: modules, bundled assets, tested versions
bin/diva             install / update / uninstall / status / test
theme/<name>/        Omarchy themes  -> ~/.config/omarchy/themes/<name> (six: diva, diva-lavande, …)
hypr/diva.lua        window look     -> ~/.config/hypr/diva.lua
plugin/              shell plugin    -> ~/.config/omarchy/plugins/io.github.tdemers218.diva
  manifest.json        kinds: overlay + bar-widget
  Diva.qml             the pink menu: greeting, text line, grid of big buttons
  BarWidget.qml        the "Diva" button in the bar
  core/Actions.js      action registry and French phrase matching, typo tolerant (pure functions)
  core/Smart.js        levels, sums, time, sites, web search, learned shortcuts, AI intents
  DivaAvatar.qml       Diva, a robot drawn with QtQuick.Shapes: moods, gaze, reactions
  Companion.qml        Diva on the desktop: the plugin's `service` entry, a Bottom-layer corner window
  BarWidget.qml        Diva's face and name in the bar
  ResultsView.qml      what she typed, in sections; arrow keys move by position on screen
  ResultCard.qml       one result, drawn the way its section calls for (preview, pill, icon, row…)
  HomePanel.qml        favourites and the control centre shown before she types
  DivaSlider.qml       the control centre's thick sliders
  core/Icons.js        named icon glyphs (Material Design set of Omarchy's Nerd Font)
  SettingsPage.qml     settings inside the menu (name, assistant sign-in, look, advanced)
  PluginsPage.qml      marketplace browser and installed-plugin manager
  Diva{Button,Switch,Input}.qml   the controls those pages use
  bin/diva-ai          optional assistant: one Messages API call, prints one JSON line
  bin/diva-plugins     marketplace catalog + `omarchy plugin` wrapper, prints one JSON line
  bin/diva-power       battery care: levels of cuts on battery, all undone on mains
  PetDetector.qml      notices a shaken pointer (four quick changes of direction)
  bin/diva-run         runs one action and verifies that it happened
  bin/diva-doctor      inspect / repair / verify / undo / report, with a journal
  skills/depannage.md  the troubleshooting skill given to the assistant
  bin/diva-window      window moves as fixed Hyprland dispatchers (focus, close, float, resize, workspace…)
  bin/diva-state       reads and sets volume, brightness, Wi-Fi, Bluetooth; prints one JSON line
  bin/diva-install     installs YouTube / Netflix (web apps) or Stremio (Flathub), by fixed name
  fonts/Fredoka.ttf    bundled rounded typeface (OFL)
tests/tst_actions.qml
```

- **Appearance**: an ordinary Omarchy theme styles the desktop. Diva's menu uses its own fixed pink palette and font, so it stays pink under any theme.
- **Menu**: replaces the Omarchy menu's two entry points, its bar button and `SUPER + SPACE`. The `omarchy.menu` plugin stays enabled: Omarchy's pickers (`omarchy-menu-select`, theme and background switchers, power and capture menus) are drawn by it, and a full replacement through `omarchy.clonedFrom` would have to reimplement all of them. Restarting and shutting down ask for a second click. With nothing typed it shows every action as a button; typing filters actions and installed applications. Mouse, arrows, Enter and Esc all work.
- **Requests** are resolved in this order, all locally: a learned shortcut for exactly these words, a level (`volume à 40`), a sum, a search that starts with `cherche`, then registry actions, well-known sites and installed applications. A request that is still open gets "Demander à Diva" (when the assistant is on) and "Chercher sur Internet". Every result is a tile, and `Smart.argv()` turns a tile into a fixed-shape argv; no text is ever run as a command.
- **Assistant**: `bin/diva-ai` builds Diva's personality prompt, the action ids and the application names, and asks a model for `{reply, intent}` as structured output. `ai.provider` picks the route:
  - `claude` (default): the Claude Code CLI on her subscription login, `claude -p … --json-schema … --tools "" --no-session-persistence --setting-sources "" --strict-mcp-config --model <alias>`, from an empty folder, so no tool, session, memory or project setting is involved.
  - `chatgpt`: the Codex CLI on her ChatGPT login, `codex exec --skip-git-repo-check --ephemeral -s read-only -m <model> -c model_reasoning_effort="low" --output-schema … -o …`, from the same empty folder; Codex has no system-prompt flag, so the personality precedes the request in the prompt.
  - `anthropic`: the Messages API with a key.

  `--login` runs `claude auth login --claudeai` or `codex login` (browser sign-in). `--status` reports, per subscription, whether its CLI exists, whether she is signed in, the plan when known (never the address), the model list with its French "best for" lines, and the chosen model (`ai.models.<provider>`). The ChatGPT list is filtered against `codex debug models`, so only models that Codex really lists are offered. An intent is one of `action`, `app`, `url`, `search`, `volume`, `brightness`, `none`; `Smart.intentTile()` rejects an unknown action, a missing application or a non-https address, and anything marked `confirm` still asks for a second click.
- **Bar and lock**: `theme/diva/shell.toml` is Omarchy's generated shell theme for these colours with a few values changed (bar and popup alpha, bar height, type scale, lock field colours); a theme's own `shell.toml` replaces the generated one. `hypr/diva.lua` adds a blur rule for the `omarchy-*` layers that become translucent. Nothing of Omarchy's bar or lock code is cloned.
- **Films**: `Smart.MOVIES` lists YouTube, Netflix and Stremio. An installed app is matched by Flatpak id or by name and opened; otherwise the tile is an install offer that, once confirmed, runs `bin/diva-install <name>`: `omarchy-webapp-install` for the two sites, and for Stremio a per-user Flathub remote plus `flatpak install --user`, in a visible terminal.
- **Icons and avatar**: tiles name a glyph in `core/Icons.js` (checked against JetBrainsMono Nerd Font) drawn in one colour; nothing Diva writes contains an emoji, and the assistant is told not to use any. The avatar is vector shapes on a 100 x 100 grid. Its mood is one derived property of the menu (`thinking`, `love`/`sad` flashes, `happy`, `sleepy`, `shy`, `curious`, `idle`); a `HoverHandler` over the whole panel feeds the pointer's position to her gaze (`lookX`, `lookY`) and to `near`, which makes her lean, grow a little and blush.
- **Diva outside the menu**: the plugin declares three kinds. `overlay` is the menu, `bar-widget` draws `DivaAvatar` at bar height, and `service` (`Companion.qml`) is mounted with the shell and owns a small layer-shell window on the Bottom layer, whose input mask is the avatar alone so the rest of the desktop keeps its clicks. The window now covers the whole screen so she can be dragged anywhere; her position is stored as fractions of the screen in `~/.local/state/diva/companion.json`, and one press serves both uses (a click opens the menu, a drag past 8 px carries her). The three do not share state; the companion reads `config.json` and `bin/diva-state` itself. Both outside avatars keep `animate` false except while hovered, speaking, or during a three-second glance every thirteen seconds, so they do not keep the compositor drawing.
- **Motion**: two bezier curves (`divaSpring`, `divaSoft`) and `hl.animation` overrides for windows, fades, borders, layers, workspaces and the scratchpad, plus layer rules that slide notifications in and leave Diva's own surfaces to animate themselves. No animation loops forever (no rotating border), to spare the battery.
- **Navigation**: when the menu opens it reads `hyprctl clients -j` (open windows, with each application's icon looked up by window class) and, once per session, `omarchy menu keybindings --print` (the live bindings). `Smart.matchWindows` offers open windows; `Smart.WINDOW_ACTIONS` and `parseWorkspace` offer moves, run by `bin/diva-window`, whose every operation is a fixed dispatcher string and whose only outside values are a checked window address and a workspace number. Diva's menu is a layer, not a window, so "the window she was in" is simply the active window again once the menu has closed; the helper waits 180 ms for that, except for resizing, which keeps the menu open and acts at once. `Smart.GUIDE` holds the explanations with `{Omarchy binding description|fallback}` placeholders filled from the live bindings and worded in French (`keyLabel`); a how-to question is answered from it locally, and the same lines go to the assistant.
- **Result layout**: `Smart.resolve` still returns tiles ranked by score; `Smart.layout` then groups them by kind into `SECTIONS` (`answer`, `windows`, `window`, `do`, `open`, `settings`, `ask`), orders sections by their best score (answers first, `ask` last unless the assistant is the best answer), numbers every tile in display order and reports where the best one landed, which is what Enter runs. `ResultCard` draws one tile in its section's style on a shared frame. Window cards use Quickshell's `ScreencopyView` on the window's Wayland toplevel, live only while the card is shown.
- **Fuzzy matching**: `Actions.fuzzy` accepts typed letters found in order from the start of a word, weaker the more letters are skipped; `Actions.loose` (a beginning, else fuzzy) is used for application, window and setting names, and Diva's own phrases accept it from four letters. Scores are multiplied by the match quality, so exact matches lead.
- **Verified actions**: `Smart.check(tile)` names what must be true after a tile runs (`launch`, `focus:<address>`, `closed`, `float`, `fullscreen`, `state:<field>:up|down|toggle|=N`, or `none`). `bin/diva-run` snapshots the state, runs the argv, polls for the change and prints `{ok, verified, detail}`; `ok` is false only on evidence of failure, and `verified` is false when nothing could be observed either way. `Diva.qml:ran()` then replies, learns a pending shortcut only on `ok && verified`, or reports the failure (in the menu, or as a notification once it has closed).
- **Troubleshooting**: the controller is `Diva.qml` (`task`, `phase`, `steps`), not the model. A request starts a task at the `daily` level. `diagnose` makes the controller run `diva-doctor inspect` and ask again with the result and the skill; `repair` makes it apply one listed repair, verify it, inspect again and continue while something is still wrong, up to two repairs. The model only ever names an intent. `diva-doctor` also refuses a fifth repair within ten minutes whoever asks.
- **Two levels**: `level` in the request selects the model (`ai.models.<provider>` or `ai.deep.<provider>`; defaults Sonnet/Opus and Luna/Sol). Escalation happens once per task: asked for by the daily model (`escalate`, `reason`), or triggered by the controller after a verified failure or when inspection finds several problems. The deep request carries the checked state, the attempts and the reason. Nothing else changes with the level.
- **Journal and reports**: every repair appends `{at, repair, undo, note}` to `~/.local/state/diva/journal.jsonl`; `undo` reverts the last reversible one and marks it. `report` writes a Markdown diagnostic under `~/.local/state/diva/reports/`.
- **Battery care**: `bin/diva-power apply` reads UPower (on battery, percent, smoothed time to empty), picks a level from `power.mode` and those readings, and moves to it. Desktop cuts are `hyprctl eval` overrides on top of the config; changing level reloads the config and re-applies what the new level still cuts, so nothing can be left behind, and a reload by someone else is noticed and repaired at the next tick. Profile, Bluetooth, screen and keyboard cuts each store the previous value in `~/.local/state/diva/power.json` and are reverted only when still as Diva set them. Omarchy's own per-source power profile is respected: Diva only tightens to `power-saver` and gives back what was there. `Companion.qml` runs it every 30 s and announces level changes; `bin/diva uninstall` runs `restore` first.
- **Themes**: every folder under `theme/` is installed as an Omarchy theme; `diva` is applied on a first install and the others are only made available. Each has `colors.toml`, `icons.theme`, wallpapers, a preview and a `shell.toml` derived from Diva's glass one with that theme's colours. The settings page lists them from a table in `Diva.qml` (`themes`) and switches with `omarchy-theme-set`; the theme in use is read from Omarchy's `current/theme.name`. Diva's own menu keeps its plum glass under every theme. Uninstall removes all of them and returns to the theme that was in use before Diva.
- **Screensaver**: Omarchy's launcher always runs its own `omarchy-screensaver`, with every effect, and offers no setting for either. So the pack switches Omarchy's off with its own toggle (`~/.local/state/omarchy/toggles/screensaver-off`, only if it was on) and Diva's desktop service starts hers from an `IdleMonitor` set to `idle.screensaver` in `shell.json`. `bin/diva-screensaver-launch` opens the same fullscreen terminal with the same window class, so Omarchy's idle and lock handling still recognise it; `bin/diva-screensaver` puts her name, her face (`plugin/art/robot-*.txt`) or both on stage, then either runs `ttfx` with one of twenty-three effects in her colours or plays one of four scenes drawn in the script itself with cursor moves (`scene_hearts`, `scene_sparkles`, `scene_shimmer`, `scene_face`). `DIVA_SCENE` and `DIVA_ART` force one, for checks. The logo is `branding/screensaver.txt`, installed over Omarchy's with the previous one kept and restored on uninstall (unless she has drawn her own since).
- **Glass**: the card is a translucent rectangle; the blur behind it is Hyprland's, switched on for the `diva-menu` layer by one `hl.layer_rule` in `hypr/diva.lua` with `ignore_alpha` so the faint veil around the card stays sharp. Without that rule (`--no-look`) the card is simply translucent.
- **Control centre**: `bin/diva-state` prints `{volume, muted, brightness, wifi, network, bluetooth}` and takes `volume N`, `brightness N`, `mute`, `wifi`, `bluetooth`. Volume goes to the sink `omarchy-audio-output-sink` names, the one Omarchy's own keys drive. Slider drags are coalesced: only the latest value is sent once the previous call returns.
- **Conversation**: `Smart.looksLikeQuestion()` puts "Demander à Diva" first for questions when no exact local answer exists. The menu keeps the exchange in memory (never on disk) and sends the last eight lines with each follow-up.
- **Learning**: when the assistant's intent passes those checks, the request's meaningful words and the intent are saved to `~/.local/state/diva/learned.json`. The same words later resolve from that file without a call.
- **Omarchy's menu** is read from `default/omarchy/omarchy-menu.jsonc` and the user's extension file (`Smart.parseCommands`). A match becomes a tile that runs `omarchy-menu summon <id>`, so Omarchy applies its own conditions and confirmations. Labels stay in English; they are for maintenance.
- **Marketplace**: `bin/diva-plugins list` keeps a day-old copy of `https://plugins.omarchy.org/catalog.json` (about 12 MB, 4,948 listings) in `~/.cache/diva/` and returns the 40 best-starred installable matches. Only `https://github.com/<owner>/<repo>` sources are offered. Install, remove, enable, disable and update call `omarchy plugin`; install and remove need a second click, and Diva never offers to remove or disable herself.
- **Window look**: one Diva-owned file plus one marked `require("hypr.diva")` line in `hyprland.lua`, taken out again if `hyprctl configerrors` reports anything. Translucency reuses Omarchy's `default-opacity` window tag, which browsers and video apps already opt out of.
- **API key**: typed in Settings, piped to `~/.config/diva/api-key` through a process's stdin under `umask 077`; it is never in `config.json` or on a command line.
- **Animations**: fades and scales only (open/close, staggered buttons, selection, the assistant thinking), driven by one `reveal` value; `"animations": false` sets every duration to zero.
- **Settings**: `~/.config/diva/config.json` (`name`, `movieUrl`, `searchUrl`, `animations`, `ai.enabled`, `ai.model`, `ai.keyFile`, `ai.baseUrl`), reloaded when the file changes. There is no settings screen yet.
- **Pack state**: `~/.local/state/diva/` (`install.json`, timestamped `backups/`). The checkout is never written to at runtime.
- **Ownership**: Diva adds one plugin folder, one theme folder, one bar entry in `shell.json` (in place of the Omarchy menu button, whose position is recorded), and one marked block in `bindings.lua`. Uninstall removes exactly those and puts the Omarchy button and shortcut back; a round trip left `shell.json` and `bindings.lua` byte-identical on this account. Her `config.json` is kept.

## Dependency decisions

| Dependency | Decision | Why |
| --- | --- | --- |
| `evindor.keystroke` | Not used | Was installed on the test account to try it; Diva has its own menu. Diva neither needs nor removes it. |
| `io.github.tdemers218.hyprworld` | Not managed by the pack | Installed on the test account, but not yet evaluated for her workflow; it needs a native helper built per Hyprland version |
| Fredoka | Bundled in the plugin | Rounded typeface for the menu; OFL-1.1, license in `plugin/fonts/OFL.txt` |
| Noto Color Emoji | Assumed present | Button pictures are emoji; the font ships with this Omarchy install |

## Open questions

- **Fresh-machine install is untested**; so is a French-locale system. The clock, Omarchy's own panels (Wi-Fi, Bluetooth, sound) and app names follow the system language, which Diva does not set.
- **Update flow.** `omarchy update` runs `post-update` hooks but does not update plugins. A `post-update` hook calling `bin/diva update` is the supported-looking integration point; not built yet. `bin/diva update` currently fast-forwards the checkout's branch rather than installing tagged releases.
- **Omarchy's own menus are English.** They are still reachable by their shortcuts (`SUPER + ESCAPE`, `SUPER + ALT + SPACE`…); whether to unbind or translate them is undecided.
- **Assistant**: verified with real calls on a Claude Pro subscription (about 5 to 7 seconds each). Haiku, Sonnet and Opus all answered on this Pro account. The CLI for the chosen subscription must be on her laptop; the pack does not install it, and every call counts against the subscription's usage limits. **ChatGPT was only run against a stand-in for the Codex CLI** (nobody is signed in to Codex here), so its real answers, speed and schema handling are unverified. The browser sign-in buttons and the API-key provider were not exercised end to end.
- **Lock screen**: only its colours and shape are themed. Its prompt is hard-coded English ("Enter Password") in Omarchy's lock plugin; changing it, or adding a clock or Diva, would mean maintaining a clone of the code that guards the session, which the pack does not do.
- **The larger type scale** in the Diva theme also enlarges Diva's menu and every Omarchy panel by about 8 %.
- **Netflix playback** in Omarchy's Chromium (DRM) was not tested; only creating the web app was. Installing Stremio was checked up to resolving it on a per-user Flathub remote, not downloaded.
- **Voice** is not started; voxtype is installed on this account.
- **Typed levels** (`volume à 40`) still use `wpctl` on the default sink, unlike the control centre's slider, which uses Omarchy's sink.
- **Desktop motion** was accepted by Hyprland and its values read back; how it feels on the target laptop's integrated graphics is untested, and each `hl.animation` line can be deleted on its own.
- **The desktop companion** is hidden whenever windows cover the corner (she is on the layer below them, by design). Its low-battery line and night-time dozing were not triggered.
- **Battery care was walked through every level with simulated readings** (the machine was on mains): shadows, blur, translucency, animations and the power profile were seen to change and to come back. The screen dim, Bluetooth and keyboard-light cuts did not trigger here (screen already low, Bluetooth in use, no keyboard light), and no real discharge was observed, so the estimates and the half-minute loop on battery are untested.
- **Petting** is covered by tests of the detector; nobody has shaken a real pointer at her yet.
- **Troubleshooting was exercised on real faults made for the purpose**: a muted sound (found, repaired, verified), then a muted sound with Bluetooth off (escalated to Opus, both repaired, re-checked). The ten-minute limit also fired for real during testing and produced a report. `restart-audio`, `restart-wifi`, `restart-bluetooth`, `restart-shell`, `rescan-plugins` and the two resets were not run; `reset-settings` was only seen to refuse a readable file. The Stop button was not pressed.
- **Window moves**: floating and re-tiling a real window through the menu worked. Close, fullscreen, swap, resize, workspace moves and going to another window use the same path but were not each run. Resizing needs a neighbour: a window alone on its workspace has nothing to resize against.
- **Sliders and switches were not operated by hand.** The helper behind them was tested directly; dragging, and switching Wi-Fi or Bluetooth off from the menu, were not. Night light has no state shown.
- **Pointer following** was checked by placing the pointer and opening the menu (gaze, proximity and hover all registered); continuous motion could not be simulated.
- Clicking a button was verified through IPC and screenshots, not by a real key press or click from a person.
- **Installing from the marketplace was not exercised**: listing, the URL checks and enable/disable/remove (on a throwaway local plugin) were. Listings are shown in their authors' English.
- **Blur and translucency** are untested on the target laptop's integrated graphics; `hypr/diva.lua` says where to turn blur off.
- Hyprland has no title-bar buttons; closing is `SUPER + Q` / `SUPER + W`. A title-bar plugin (hyprbars) was not evaluated.
- Cursor theme and movie-service compatibility are not chosen.
- Target hardware (EliteBook 850 G6): responsiveness, battery and suspend/resume are untested.

### Diva desktop navigation

`Service.qml` loads `Desktop.qml` and `Companion.qml` independently as part of
the persistent service, even when Diva's companion is hidden. `diva.desktop show`, `hide`, `toggle`, and `showApp`
are Quickshell IPC methods. A two-pixel overlay on each output opens the overview
after a 250 ms dwell; it re-arms only after the pointer leaves the top edge.
Four-finger up/down gestures open/close the same overview. Three-finger horizontal
swipes move Hyprland's native scrolling tape. New columns start at full width;
Diva's explicit side-by-side action resizes a pair without changing that default.

`DesktopModel.qml` snapshots the native Hyprland and desktop-entry models outside
removal callbacks. Signatures prevent unchanged samples from rebuilding dock
items. `core/Desktop.js` matches application identities, deduplicates pinned and
running applications, computes the magnification falloff, and lays out the overview.
`Dock.qml` lives next to Diva's face in the bar and uses stable hit areas; its
scrollable width is capped so a long running-app list cannot grow without bound.
A click focuses the app's most recently used window (`Desktop.byRecency`), or the
one before it when that window already has focus. Hovering an open app for 380 ms
opens a `PopupWindow` anchored to its icon with one live `ScreencopyView` per
window, to pick or close a particular one; it closes 280 ms after the pointer
leaves both the icon and the popup. The filtered overview (`showApp`) remains as
an IPC method but the dock no longer opens it. Right-click toggles a installed application's pin in
`~/.config/diva/config.json`. Unknown applications remain focusable while running.

`OverviewView.qml` animates live `ScreencopyView` surfaces between window geometry
and a map of the chosen workspace. This is a shell animation, not a compositor
camera transform. Previews stop capturing when closed. All layout changes share one duration and curve (`pace`), so position and size
move together and neighbouring tiles do not cross; outlines around tiles fade out
while a layout change is travelling and back in once it has arrived, and only a
change of tile geometry counts as one. Workspace thumbnails select
a workspace on hover (after a short dwell), enter it on click, and accept dragged
windows.

The map is `Desktop.map()` in `core/Desktop.js`: one scale for the whole
workspace, so tiles keep the windows' real proportions and positions on the
scrolling ribbon. Tab groups collapse into one tile (the most recently focused
member stands for it), columns and stacks are recovered from the left edges, and
floating windows are drawn last, on top. Below a scale of 0.2 the map stops
shrinking and scrolls instead. The app-filtered view (`showApp`) has no shared
layout to draw and uses `Desktop.gallery()`, an even grid in each window's own
proportions, with editing switched off. `OverviewTile.qml` is one tile; tiles live
in a `ListModel` keyed by window address so that a tile that moved or changed
size animates there instead of being rebuilt, which also keeps its screen copy.

Changes go through `bin/diva-window` by window address, one at a time from a
queue in `Desktop.qml`: `arrange <window> <target> before|after|stack|pair|group`,
`width <window> <percent>`, `resize-address` (floating only), `ungroup`,
`own-column`, `float-address`, `close-address`, `move-address`. Hyprland's
scrolling layout only rearranges the focused column, so `with_focus` focuses the
window, sends the layout message (`swapcol`, `colresize`, `promote`) and restores
focus inside a single `hyprctl eval`; it acts only once it has confirmed the
focus moved. Hyprland refuses that focus while a layer holds the keyboard
exclusively, so the overview panel drops to no keyboard focus for the duration of
a change. A relative `window.resize` on a tiled column by address was observed to
collapse the column, which is why tiled widths always use `colresize`. While the
overview is open `DesktopModel` re-reads Hyprland's window list about three times
a second, and immediately after each change.

`pair` is the shared screen: two neighbouring columns of about half a screen
(40 to 60 percent) count as one. A window dropped on a lone window is placed
after it and both columns are set to half; dropped on a shared screen it is
stacked into the half it was dropped on if that half holds one window, else into
the other half, and a screen of four quarters sends it beside to start the next.
`Desktop.screens()` and `joinKind()` make the same decision in the view, for the
frames and for what Diva announces; `group` (tabs) is only reached with Shift or
the T key. `Desktop.dock()` orders running apps by `inOrder` (workspace, then
left edge, then top), and `DesktopModel` re-reads positions on Hyprland events so
the dock follows a rearrangement.

`alone <window>` is the way back out, reached by dropping a dragged tile on
nothing once the pointer has left the rectangle of what it shares
(`Desktop.leaveKind`: its tab group, its shared screen, or its stack), or with
Shift + G. Out of a shared screen the window goes to the right of it at full
width and the rest closes up: one window left gets the full width, two left
stacked in one half are split into two halves. A tab is taken out by dragging its
icon off the tile. The view never assigns its own `workspace` or `appFilter`
(that would cut the binding from `Desktop.qml` and reopen the overview on a stale
workspace); it emits `workspacePicked` and the owner sets it.

`diva.desktop map` returns the tiles as drawn and `diva.desktop drop <address> <x>
<y> <tabs>` replays a drop at a point; both exist for checks. Adding an empty
workspace keeps a placeholder for this service's lifetime; activation or moving a
window creates the actual Hyprland workspace. Existing named workspaces are kept.
The installer records complete removed workspace-widget entries and restores them
on uninstall, preserving inline settings and user layout choices.

`ControlPage.qml` contains Wi-Fi, Bluetooth, audio, and wallpaper views inside the
Diva menu. Wi-Fi uses Quickshell Networking and passes PSKs directly to
NetworkManager. Bluetooth uses Quickshell's live devices and the existing fixed
Omarchy device helper, checking the resulting state. Audio uses tracked PipeWire
nodes, output/input selection, microphone controls, and per-application volume.
Wallpaper discovery and selection use `diva-wallpapers`, which only permits images
in the current theme and its user wallpaper directory. These pages do not open
Omarchy's panels. Unknown enterprise Wi-Fi profiles still require provisioning;
existing profiles can connect here. This release does not reproduce the stock
panels' advanced DNS, speed-test, audio-tuning, or diagnostics tools.

Verification: `bin/diva test` includes pure QML behaviour tests and isolated
wallpaper/install/update/uninstall tests. `tests/preview.sh` runs a separate
Quickshell instance offscreen, checks the available non-layer-shell components compile, and renders control
and overview fixtures. It does not exercise real radios, the live compositor,
touchpad hardware, or live window capture; those need an interactive desktop test.

### Priority fixes after the 6 October 2026 review

- `diva-power`: cuts go on mildest first and come off in reverse, so the level-3
  brightness cap is lifted before the level-2 dimming (which otherwise saw a
  brightness it had not set and left it). `level_for` holds a level until the
  reading clears its threshold by a margin. Checked by `tests/test_power.sh`
  against stand-in commands.
- `diva-run` reports `state`: `verified`, `launched` or `failed`. With nothing to
  observe it waits briefly for the command's own exit code. `launch:<app id>`
  only counts a window of that app. `Diva.qml` (`judge`) treats an unreadable
  answer as undetermined, and queues an action asked for while another is being
  checked (`waiting`) instead of running it detached.
- `diva-doctor inspect [areas]` returns `problems`, `choices` and `elsewhere`;
  `Smart.symptomAreas()` derives the areas from the request by keyword. The
  troubleshooting skill tells the model to leave `choices` alone.
- `DesktopModel` is driven by Hyprland's raw events (positions at most four
  times a second, titles once a second) with a 5 s safety tick, instead of a
  700 ms poll in each of its two instances. The screensaver runs its effects at
  20 frames a second on battery.

