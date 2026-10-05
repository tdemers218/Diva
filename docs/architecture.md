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
theme/diva/          Omarchy theme   -> ~/.config/omarchy/themes/diva
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
- **Diva outside the menu**: the plugin declares three kinds. `overlay` is the menu, `bar-widget` draws `DivaAvatar` at bar height, and `service` (`Companion.qml`) is mounted with the shell and owns a small layer-shell window on the Bottom layer, anchored bottom-right, whose input mask is the avatar alone so the rest of the corner still belongs to the desktop. The three do not share state; the companion reads `config.json` and `bin/diva-state` itself. Both outside avatars keep `animate` false except while hovered, speaking, or during a three-second glance every thirteen seconds, so they do not keep the compositor drawing.
- **Motion**: two bezier curves (`divaSpring`, `divaSoft`) and `hl.animation` overrides for windows, fades, borders, layers, workspaces and the scratchpad, plus layer rules that slide notifications in and leave Diva's own surfaces to animate themselves. No animation loops forever (no rotating border), to spare the battery.
- **Navigation**: when the menu opens it reads `hyprctl clients -j` (open windows, with each application's icon looked up by window class) and, once per session, `omarchy menu keybindings --print` (the live bindings). `Smart.matchWindows` offers open windows; `Smart.WINDOW_ACTIONS` and `parseWorkspace` offer moves, run by `bin/diva-window`, whose every operation is a fixed dispatcher string and whose only outside values are a checked window address and a workspace number. Diva's menu is a layer, not a window, so "the window she was in" is simply the active window again once the menu has closed; the helper waits 180 ms for that, except for resizing, which keeps the menu open and acts at once. `Smart.GUIDE` holds the explanations with `{Omarchy binding description|fallback}` placeholders filled from the live bindings and worded in French (`keyLabel`); a how-to question is answered from it locally, and the same lines go to the assistant.
- **Result layout**: `Smart.resolve` still returns tiles ranked by score; `Smart.layout` then groups them by kind into `SECTIONS` (`answer`, `windows`, `window`, `do`, `open`, `settings`, `ask`), orders sections by their best score (answers first, `ask` last unless the assistant is the best answer), numbers every tile in display order and reports where the best one landed, which is what Enter runs. `ResultCard` draws one tile in its section's style on a shared frame. Window cards use Quickshell's `ScreencopyView` on the window's Wayland toplevel, live only while the card is shown.
- **Fuzzy matching**: `Actions.fuzzy` accepts typed letters found in order from the start of a word, weaker the more letters are skipped; `Actions.loose` (a beginning, else fuzzy) is used for application, window and setting names, and Diva's own phrases accept it from four letters. Scores are multiplied by the match quality, so exact matches lead.
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
- **Window moves**: floating and re-tiling a real window through the menu worked. Close, fullscreen, swap, resize, workspace moves and going to another window use the same path but were not each run. Resizing needs a neighbour: a window alone on its workspace has nothing to resize against.
- **Sliders and switches were not operated by hand.** The helper behind them was tested directly; dragging, and switching Wi-Fi or Bluetooth off from the menu, were not. Night light has no state shown.
- **Pointer following** was checked by placing the pointer and opening the menu (gaze, proximity and hover all registered); continuous motion could not be simulated.
- Clicking a button was verified through IPC and screenshots, not by a real key press or click from a person.
- **Installing from the marketplace was not exercised**: listing, the URL checks and enable/disable/remove (on a throwaway local plugin) were. Listings are shown in their authors' English.
- **Blur and translucency** are untested on the target laptop's integrated graphics; `hypr/diva.lua` says where to turn blur off.
- Hyprland has no title-bar buttons; closing is `SUPER + Q` / `SUPER + W`. A title-bar plugin (hyprbars) was not evaluated.
- Cursor theme and movie-service compatibility are not chosen.
- Target hardware (EliteBook 850 G6): responsiveness, battery and suspend/resume are untested.
