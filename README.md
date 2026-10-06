# Diva

An Omarchy plugin pack that girlifies the operating system. Includes **Diva**, a personal girly assistant to make everyday navigation simple.

> **Status: working prototype, version 0.13.0.** The "Implemented so far" section below lists what works on the test account, which is the only place it has run. Phases 1 to 3 of the build order are largely in place; voice, release-based updates and the target laptop are not. From "The goal" onward, this README is the original brief, kept as written.

## Implemented so far

Tested on Omarchy 4.0.4, on the dedicated test account only. See [docs/architecture.md](docs/architecture.md) for verified mechanisms and open questions.

- **Six themes** (`theme/*`), chosen in Diva's settings (gear › Apparence) or by typing "thème". Each is a full Omarchy theme with its own colours, wallpapers and glass bar:
  - *Prune* (`diva`): dark plum and dusty rose; dusk photographs.
  - *Lavande*: indigo night with lavender; Monet's mauve water lilies, Webb's Cosmic Cliffs, an aurora.
  - *Menthe*: deep blue-green with mint and blossom pink; Van Gogh's almond blossom, Monet, a lagoon.
  - *Pêche*: warm cocoa with peach; Hokusai's Red Fuji and poppies, a Redon bouquet.
  - *Crème*: the one light theme, warm cream rather than white; Hokusai's irises and Great Wave, white blossom, roses.
  - *Minuit*: near-black with hot pink; Redon's poppies on black, city lights.

  All 26 wallpapers are public domain or CC0, credited per theme in `theme/<name>/backgrounds/CREDITS.md`.
- **Window look** (`hypr/diva.lua`), for someone used to macOS: rounded corners, slightly translucent windows with a light blur (browsers and video stay opaque), soft shadows, natural scrolling, tap to click, a scrolling ribbon of full-width windows moved with three fingers, and `SUPER + Q` to close a window. `bin/diva install --no-look` skips it.
- **Diva's own menu** (`plugin/`), an Omarchy shell plugin, entirely in French, drawn as frosted glass in the manner of recent macOS: a translucent card blurred by the compositor, hairline highlights, large soft corners, one icon set and no emoji.
- **Diva herself is always there**: a small pink companion robot with a heart on her antenna, beside a speech bubble where everything she says appears. She floats, blinks at uneven moments, follows the pointer with her eyes, blushes and leans in when it comes close, nods as you type, looks curious at a question, pulses while she thinks, dozes off when nothing happens and wakes with a word, and answers a click with a hop, a burst of hearts and a line of her own.
- **Diva beyond her menu**: her face replaces the heart in the bar (she waves when the bar appears, looks at the pointer and blushes when it is over her), and she sits in the bottom-right corner of the desktop, behind the windows: she says hello a few seconds after the session starts, glances around now and then, dozes between 23 h and 6 h, warns once when the battery drops under 20 %, and opens her menu when clicked. She can be picked up and dropped anywhere on the desktop and remembers the spot (`~/.local/state/diva/companion.json`); her bubble opens on whichever side has room. She moves only in short bursts, so an idle desktop stays idle. "Diva sur le bureau" in the settings hides her.
- **Petting**: shake the pointer from side to side close to Diva, in her menu, on the desktop or over her face in the bar, and she leans into it, sends up a few hearts and says so ("Mmh, encore."). Four quick changes of direction count; a pointer merely passing by, or resting, does not.
- **Battery care, in the manner of macOS** (`bin/diva-power`, run every half minute by Diva's desktop service): automatic, quiet, and cutting what shows least first. Plugged in, nothing is held back.
  1. *On battery*: Diva's own idle motion, window shadows, and one blur pass instead of two.
  2. *Under 50 % or 2 h 30 left*: blur and window translucency off, the power-saver profile, Bluetooth off if nothing is connected to it, the screen 15 points dimmer if it was bright.
  3. *Under 20 % or 45 min left* (low power mode): desktop animations off, the screen capped at 40 %, keyboard light off.

  The time left comes from the recent power draw, so a heavy afternoon reaches level 2 sooner than a quiet one. Each cut remembers what was there and is undone only if it is still as Diva left it: a brightness she changed herself stays hers. The control centre shows "Batterie 64 %  ·  environ 3 h 25  ·  j'économise", Diva says a word when she changes level, and the settings offer Automatique / Toujours économiser / Jamais.
- **Screensaver**: Omarchy's screensaver keeps its idea (text drawn by terminal effects) but becomes Diva's: her name in round letters with a heart dotting the i and sparkles around it, sometimes her face, sometimes both, on deep plum instead of black, in pinks and lilacs. Twenty-three gentle effects draw it (bubbles, fireworks of hearts, petals and flowers falling, bouncing hearts, beams of hearts, pink smoke, waves, rings, swarms, sweeps…), and four scenes are Diva's own: hearts and flowers drifting up either side of her, sparkles twinkling around her, a shimmer of colour through her name, and her face blinking, winking and smiling. None of the "hacker" ones (matrix rain, decryption, binary, glitches) are used. It starts after the idle time Omarchy is set to, can be switched off in Diva's settings, and "écran de veille" starts it on demand.
- **Motion everywhere** (`hypr/diva.lua`): windows pop in with a small bounce and shrink away, glide when the layout makes room, and cross-fade their rim and dimming on focus; workspaces slide and fade; notifications and reminders slide in from the right; the volume display pops; the scratchpad drops from above. Inside the menu, pages slide up, conversation lines rise into place and extension cards fade in one after another.
- **Getting around, with Diva's help**:
  - *Finding windows*: typing an application's name or words from a window's title offers the open window first ("Brave Browser, recette de soupe…") before opening the app again. "Mes fenêtres", among the favourites, lists everything open.
  - *Acting on the window she was in*: fermer, plein écran, agrandir, détacher ou ranger (floating/tiling), plus large, moins large, à gauche, à droite, changer le partage, fenêtre suivante, garder au premier plan, by button or by words ("ferme la fenêtre", "mets la fenêtre à gauche"). "Envoie la fenêtre sur l'espace 2" and "va sur l'espace 3" work too.
  - *Explaining*: "comment je ferme une fenêtre ?", "pavé tactile", "souris", "copier coller", "espaces", "capture d'écran" are answered in a sentence, with the keys this computer really has, read from Omarchy's live bindings. The assistant is given the same guide and told not to invent shortcuts.
  - *Settings and shortcuts*: Diva's settings and all of Omarchy's menu by French or English words, and "raccourcis" opens Omarchy's full list.
- **Results that look like what they do**: what she types is answered in sections, each with its own kind of card, so a result's nature shows before it is read. Open windows are cards with a live preview of the window; things Diva does right now (sound, light, reminders) are wide buttons; applications and sites are app icons; moves for the current window are small pills; settings are list rows showing where they live; tips are a note with the whole text; her assistant and the web are two bars at the end. The most relevant section comes first, Enter runs the best result, and the arrow keys move by what is on screen.
- **Fuzzy matching**: letters in order are enough (`frfx` finds Firefox, `tlchrgmnt` finds Téléchargements, `brv` finds the open Brave window), for applications, windows, settings and Diva's own actions. An exact beginning always ranks above a fuzzy find.
- **Home, iOS style**: favourites as app icons, then a control centre: round switches for Wi-Fi, Bluetooth, silence and night light, sliders for volume and brightness showing the real values, and buttons for sound, wallpaper, lock, restart and shut down. Wi-Fi, Bluetooth, sound and wallpaper each open their own page inside Diva (see "Dock, overview, and native controls" below). Everything else is found by typing.
- **Conversation**: a question (it ends with "?", starts like one, or is a whole sentence) goes to Diva's assistant first instead of a web search, unless Diva already has the exact answer herself. The answer opens a conversation in the menu; follow-ups keep the thread, Esc leaves it.
- **Films et séries**: YouTube, Netflix and Stremio. What is installed opens; what is not offers to install the official way, after a confirmation: YouTube and Netflix as Omarchy web apps, Stremio as its official Flathub app, per user and without a password.
- **Settings inside the menu** (the gear in its corner): her name, the assistant, animations, the wallpaper picker.
- **Finding settings by typing**: Diva's own settings and all of Omarchy's menu, commands and submenus, in French or English (`police`, `thème`, `fuseau horaire`, `mise à jour`, `clavier`). Omarchy's entries come after Diva's own answers, or alone after `>`.
- **Extensions**: Settings › Extensions browses the official marketplace ([plugins.omarchy.org](https://plugins.omarchy.org/)) on a wider card: category chips with counts, sorting (most loved, most recent, A to Z), verified only, three preview sizes (list, medium cards, large cards), more results as you scroll, and a detail view with the full-size picture, author, version, licence and a link to the code. Install asks for a confirmation; installed plugins can be enabled, disabled, updated or removed, all through `omarchy plugin`.
- **Local understanding, no network**: plain phrases (`baisse le volume`), typos (`telechargemnts`), levels (`mets le son à 40`), sums (`12*4`), the time and date, well-known sites (`mes mails`), and a web search for anything else (`cherche une recette de crêpes`).
- **AI assistant, on a subscription she already has**: Claude or ChatGPT, chosen in the menu (gear › Mon assistante). **Me connecter** opens a browser sign-in for the chosen one (no API key), **Tester** checks it, and a list lets her pick the model, each with a line on what it is best for: Haiku, Sonnet, Opus for Claude; GPT-6 Luna, GPT-6.1 Sol, GPT-6 Astra for ChatGPT. The assistant is on as soon as she is signed in. She answers like a warm, natural friend rather than an assistant, and may name one thing to do, which the menu checks against what it really has before running it. Claude runs through the Claude Code CLI and ChatGPT through the Codex CLI, so the one she uses must be installed. An Anthropic API key remains possible with `"ai": { "provider": "anthropic" }`.
- **Reminders and battery**: `rappelle-moi dans 10 minutes de sortir le gâteau` sets an Omarchy reminder; `batterie` is answered in a sentence, and Diva mentions a battery under 20 % on her own.
- **Bar and lock screen**: the Diva theme ships a `shell.toml` that makes Omarchy's bar, popups and notifications translucent glass (blurred by Hyprland), a little taller and larger in type, and gives the lock screen's password field a translucent, rose-rimmed, rounded look over the blurred wallpaper.
- **Learned shortcuts**: what the assistant resolved once is saved in `~/.local/state/diva/learned.json` and answered locally the next time, with no model call. `bin/diva learned` lists and removes them.
- **Pack manager** (`bin/diva`): install, update, uninstall, status, with backups and state in `~/.local/state/diva/`.

### Dock, overview, and native controls

Diva now keeps Wi-Fi network selection/passwords, Bluetooth devices, audio outputs
and microphones, app volume, and wallpaper selection inside her own menu. Click
the Wi-Fi or Bluetooth label, **Son**, or **Fond** to open its Diva page.

The dock beside Diva combines favourite and running apps. Icons grow smoothly as
the pointer approaches. Click to launch or return to an app; several windows open
an app-specific overview. Right-click an installed app to pin/unpin it. A long dock
can be scrolled. Workspace numbers are removed from the bar on installation and
restored with their settings on uninstall.

- Hold the pointer at the top edge for a quarter second, click **▦** in the dock,
  or swipe up with four fingers to see the overview.
- Hover an **Espace** to inspect it, click it to enter, or drag a window preview
  onto it to move the window. **+** adds an empty space to choose or move into.
- Click a window to return to it. Arrow keys and Enter also work. Escape or a
  four-finger downward swipe closes the overview.
- Three fingers horizontally scroll the window ribbon. Windows open at full
  width; ask Diva to **mettre deux fenêtres côte à côte** for an explicit pair.
- Disable the top-edge trigger in **Réglages → Bureau**; the dock and gesture
  remain available. The existing Animations setting also controls the dock and
  overview transitions.

The overview zoom animates live window previews in Diva's shell; it does not
change the compositor's camera. Advanced stock-panel administration tools are
not reproduced yet, including provisioning a new enterprise Wi-Fi profile.
Saved enterprise profiles remain usable.

Run `bin/diva install --no-theme` from the desktop to apply these pack changes
without selecting another theme. `bin/diva test` runs the checks;
`tests/preview.sh` renders an isolated offscreen preview to
`/tmp/diva-controls.png` and `/tmp/diva-overview.png`.

### Commands

```sh
bin/diva install     # safe to run again
bin/diva status
bin/diva test
bin/diva uninstall   # restores the previous theme, bar and keybindings

bin/diva ai login    # sign in to the Claude subscription in the browser (same as the menu's button)
bin/diva ai on       # switch the assistant on (ai off, ai status, ai ask "…")
bin/diva learned     # list learned shortcuts (learned forget <n>, learned clear)
```

Diva takes the place of the Omarchy menu: its button sits first in the bar and a tap of the Super key opens it. The binding fires when Super is released on its own, so Super shortcuts (`SUPER + W`, `SUPER + 2`…) are unaffected; `SUPER + SPACE` no longer opens anything. The Omarchy menu itself stays enabled behind it (`SUPER + ESCAPE` and the other Omarchy shortcuts still work), because Omarchy's own pickers are drawn by it. Her settings are changed from the menu and stored in `~/.config/diva/config.json`:

```json
{ "name": "", "animations": true, "advancedSearch": true,
  "ai": { "enabled": true, "provider": "claude", "models": { "claude": "sonnet", "chatgpt": "gpt-6-luna" },
          "deep": { "claude": "opus", "chatgpt": "gpt-6.1-sol" }, "personality": "" } }
```

### Not yet done

- Voice.
- A French lock-screen prompt (Omarchy's is hard-coded "Enter Password"); only the lock field's colours and shape are themed.
- Release-based updates: `bin/diva update` fast-forwards the checkout rather than installing a tagged version.
- A fresh-machine install, a French system locale, and any testing on the target laptop, including battery life on a real discharge.
- The assistant's CLI (Claude Code or Codex) is not installed by the pack.

What was and was not verified, feature by feature, is in [docs/architecture.md](docs/architecture.md) under "Open questions".

## Diva met ses lunettes

Toute l'expérience reste en français.

### Déjà en place

Fiabilité et dépannage

- La liste des applications s'actualise toute seule après une installation ou une suppression, même menu ouvert.
- Chaque action passe par `bin/diva-run`, qui vérifie son résultat (fenêtre apparue, volume réellement changé, fenêtre réellement fermée…). Diva n'annonce une réussite, et n'enregistre un raccourci appris, qu'après cette vérification. Un échec est dit dans le menu, ou par une notification s'il est déjà fermé.
- Compétence de dépannage : `plugin/skills/depannage.md` (architecture, problèmes connus, diagnostics, procédures), chargée dans les instructions de l'assistante dès qu'un état vérifié accompagne la demande.
- Outils contrôlés, `bin/diva-doctor` : `inspect` (son, Wi-Fi, Bluetooth, écran, batterie, disque, Diva elle-même), `repair <id>` parmi onze réparations fixes sans mot de passe, `verify <id>`, `undo`, `report`. Deux réparations au plus par demande, quatre au plus en dix minutes.

Deux niveaux de réflexion

- Les actions locales et les raccourcis appris restent prioritaires, sans appel à un modèle.
- Diva quotidienne : Sonnet avec Claude, Luna avec OpenAI. Diva avec lunettes : Opus avec Claude, Sol avec OpenAI.
- Le modèle quotidien peut demander une escalade motivée (`escalate` et `reason`). Le contrôleur la déclenche aussi après un échec vérifié, ou quand le diagnostic trouve plusieurs anomalies. Le modèle supérieur reçoit l'état vérifié, les essais précédents et la raison ; il ne recommence pas à l'aveugle.
- Une escalade par tâche. Le changement de modèle ne change pas les permissions : mêmes intentions, mêmes vérifications.

Apparence

- En réflexion approfondie, Diva porte des lunettes rondes, prend un air concentré, et un petit terminal violet apparaît sous elle.
- États réels : « Je vérifie… », « Je m'en occupe… », « Je teste… », puis le résultat, avec le détail des étapes dans le terminal et un bouton « Arrêter ».

Réparations compatibles avec les mises à jour

- Réglages et données restent hors du dépôt. Chaque réparation est écrite dans `~/.local/state/diva/journal.jsonl` avec de quoi l'annuler quand c'est possible (`bin/diva-doctor undo`). Un fichier de réglages n'est remplacé que s'il est illisible, et l'ancien est conservé.
- Quand Diva n'y arrive pas, elle écrit un diagnostic dans `~/.local/state/diva/reports/` (versions, état, essais, erreurs récentes) pour une correction dans GitHub, distribuée par une mise à jour normale. Elle ne modifie jamais ses propres sources.

### Reste à faire

- Contrôle de l'écran : rien n'en a besoin aujourd'hui, tous les outils travaillent en arrière-plan. S'il devient indispensable, il faudra la confirmation et la suspension en cas d'intervention décrites à l'origine.
- Vérification des actions « sans effet observable » (ouvrir un panneau, changer le fond, programmer un rappel) : elles sont lancées mais pas contrôlées.
- Le niveau « lunettes » avec OpenAI n'a tourné que contre un faux Codex ; avec Claude, tout a été exercé pour de vrai.
- Choisir le modèle « lunettes » depuis les réglages (aujourd'hui `ai.deep` dans `config.json`).
- Ouvrir le rapport ou préparer une issue GitHub depuis le menu.

## The goal

Diva is a personalized Omarchy experience being built for my girlfriend: cute, very pink, approachable, and usable by someone who is not familiar with computers.

**Everything she sees is in French**: the menu, Diva's replies, and the phrases Diva understands.

The ambition is to make an existing laptop feel like a polished personal computer she actually enjoys using. Appearance matters, but so does being able to open apps, find things, change settings, and watch movies without learning Linux commands or memorizing lots of shortcuts.

Diva should keep Omarchy's strengths while making its everyday interface easier to discover. She should be able to click, type a request, or speak to her assistant and get a short, useful result.

## A plugin pack, like a Minecraft modpack

Diva is one cohesive experience made from several pieces:

- Existing official Omarchy plugins and features, where suitable.
- Selected community plugins, where they solve an actual need.
- Custom Diva modules for the appearance, launcher, assistant, and integration between them.
- A coordinating layer that records what belongs in the pack and manages setup, configuration, and updates.

Reuse maintained plugins rather than rewriting their functionality. Keep upstream plugins separate and track their sources and versions; avoid quietly copying their code into one enormous plugin.

This is a personal project. Publishing to the Omarchy plugin marketplace is not a goal. GitHub is the intended place to develop and distribute updates. Marketplace-independent distribution does not require the GitHub repository to be private.

**The specific third-party plugin list has not been selected yet.** Inspect the current ecosystem before choosing dependencies. HyprWorld may be evaluated if it improves her workflow; it is not automatically a required dependency.

## What will be in it

### 1. A cohesive pink desktop

A very girly visual identity across the desktop and Diva's own interface, with readable text and clear controls.

Planned areas to bring together:

- Theme, colors, wallpaper, and suitable icons/cursor styling.
- Consistent styling for the launcher, assistant, and settings.
- Discoverable access to apps and everyday settings.
- Light visual polish that feels pleasant on an older laptop.

Exact assets and styling are still to be chosen. Prefer existing Omarchy theme mechanisms. Decorative effects should be optional if they hurt responsiveness.

### 2. Simple everyday navigation

A beginner should be able to use the computer without opening a terminal.

The launcher and visible controls should make it easy to reach:

- Applications and files.
- Volume, brightness, Wi-Fi, and Bluetooth controls where supported.
- Common desktop actions and settings.
- Movie/streaming apps or browser destinations selected during setup.

Movie access is part of the intended everyday experience, but no particular service or app has been chosen. Check the actual browser/service compatibility rather than promising playback in advance.

Mouse-friendly controls and sensible keyboard shortcuts should both work. Keep Omarchy's existing entry points available so the pack does not trap the user in a custom interface.

### 3. Diva: a personal assistant

A dedicated, cute, very girly assistant with **short, simple responses**. It should help her do things instead of delivering long technical explanations.

The intended interface is a Raycast-style launcher with text input and voice input. Typing must remain useful when voice or the network is unavailable.

Example requests illustrating the intended behavior:

- "Open my browser."
- "Turn the volume down."
- "Help me connect my headphones."
- "Where are my downloads?"
- "I want to watch a movie."

Use deterministic local actions for straightforward tasks. Use an LLM when interpreting a new request or helping with something unfamiliar adds value.

An inexpensive model is preferred. Luna was discussed as a candidate; provider, model identifier, API access, and current pricing must be verified before integration. Keep the provider configurable. Do not assume a ChatGPT subscription or Claude CLI subscription supplies API access for the runtime assistant.

**Claude CLI is the development tool; Diva is the runtime assistant.** They do not have to use the same model or backend.

Voice transcription is planned; the implementation and provider are undecided. Spoken replies can be evaluated later and are not required for the first prototype.

### 4. Learn useful local shortcuts over time

A central idea is that the assistant should gradually need less AI for repeated tasks.

1. Recognize a request using existing local actions or learned shortcuts.
2. If there is no reliable match, ask the LLM to interpret the request.
3. Resolve it to a supported action or workflow.
4. Once it succeeds and is suitable for reuse, save a local shortcut with its phrases and parameters.
5. Next time, run the shortcut locally when the match is clear.

Cache the **intent and action**, not merely the assistant's answer. For example, "open my browser" should become a reusable action that opens the configured browser, not cached text saying the browser was opened.

The longer-term vision includes an agent helping build new reusable skills as she uses the computer. Start with a small registry of known actions and parameterized workflows. Treat generated skills as a later development stage, with validation before they become executable.

Suggested first approach:

- Explicit actions and phrase aliases before embeddings or a complex matcher.
- Confidence thresholds: ambiguous matches ask one simple clarifying question.
- Store successful reusable workflows separately from transient conversation.
- Let the user inspect, rename, disable, or delete learned shortcuts.
- Treat model output as structured requests to known executors, not arbitrary shell commands.
- Require confirmation for destructive actions or external side effects such as sending messages or making purchases.

The everyday assistant should not need unrestricted administrator access. Unfamiliar requests must not silently install packages or rewrite system configuration.

### 5. One manageable pack

Diva should provide a cohesive way to configure its modules and supported dependencies, rather than requiring her to manage each piece manually.

The intended settings include appearance, enabled modules, assistant configuration, and learned shortcuts. Start with a minimal settings surface and grow it with working features.

## Development and target hardware

The initial target is an **HP EliteBook 850 G6**, with an Intel Core i5-8365U, 16 GB RAM, Intel UHD 620 graphics, and approximately 238 GB SSD storage.

Prioritize responsiveness, modest memory use, battery life, and reliable suspend/resume. A large local model or heavy permanent visual effects should not be a prerequisite.

Development will happen in a **second Omarchy user account on my own Omarchy laptop**, configured as a clean default environment resembling her installation. This account is where the pack should be installed and tested before delivering updates to her laptop.

A second user account separates user configuration; it does **not** isolate system packages, services, or every machine-wide change. Avoid changing the primary account's desktop and document any system-wide dependency. Use a disposable environment when testing changes that need stronger isolation.

## Installation and updates

The desired workflow is:

1. Develop and test on the dedicated account.
2. Commit changes to this repository.
3. Publish a tested version of the pack.
4. Update her laptop from GitHub through one simple flow.

Ideally, Diva and its managed dependencies can update alongside the normal Omarchy update workflow. **That integration must be investigated against the installed Omarchy version.** Do not invent an update hook or assume a GitHub push is automatically installed on her laptop.

First provide an explicit, reliable pack update operation. Add integration with Omarchy's update flow only if there is a supported way to do it.

Updates must preserve:

- Her theme choices and settings.
- Assistant credentials.
- Learned shortcuts and personal state.
- Configuration for plugins that she already had before installing Diva.

Suggested requirements for the pack manager:

- A manifest describing modules, dependency sources, tested versions, and ownership.
- Repeatable installation and updates; running setup twice should not duplicate entries.
- Versioned releases rather than automatically deploying every development commit.
- Backups and a practical way to return to the previous working configuration.
- Clear errors and recovery when a dependency update fails.
- Uninstall that removes Diva-owned changes and restores what it replaced, without removing pre-existing plugins or unrelated files.

Keep personal configuration and mutable state **outside the tracked checkout**. Changing settings or learning a shortcut should not dirty plugin source files or prevent future updates.

Use standard per-user config/data/cache locations as appropriate. Never commit tokens, recordings, private conversations, or machine-specific credentials. Inspect existing plugin conventions before defining the final paths and schema.

## Suggested repository organization

Adapt this after inspecting Omarchy's actual plugin format. These are responsibilities, not a requirement to create every directory immediately.

| Area | Responsibility |
| --- | --- |
| Pack manifest | Modules, upstream dependencies, sources, tested versions |
| Diva modules | Appearance, launcher, assistant, local action registry, settings |
| Lifecycle scripts | Install, update, uninstall, backups, configuration migration |
| Defaults/assets | Tracked themes and default configuration; no personal state |
| Documentation | Setup, architecture, troubleshooting, dependency decisions |
| Verification | Checks for lifecycle behavior and the complete user workflow |

Prefer a small, understandable implementation using the existing Omarchy stack. Do not introduce a large framework or rebuild the desktop shell before proving a simple working slice.

## Build order

### Phase 0 — Inspect and document

- Inspect the installed Omarchy version, plugin tooling, manifest format, theme/configuration conventions, and update lifecycle.
- Verify how the second user account is initialized; do not guess setup commands.
- Identify suitable existing plugins and record why each is needed.
- Write a short architecture note separating verified integration points from open questions.
- Decide the smallest prototype stack based on what is already installed.

### Phase 1 — Local prototype

Deliver a small but usable slice:

- Pink styling for Diva's prototype interface.
- A launcher with clickable choices and text input.
- A small set of local actions, such as opening configured apps and Downloads.
- Settings stored outside the repository.
- Install/uninstall scoped to the test account with backups.

No API key should be required for these basic actions.

### Phase 2 — Assistant and voice

- Add a configurable low-cost LLM backend.
- Return concise responses and clear action results.
- Add voice transcription and an obvious listening/cancel state.
- Handle unavailable network, missing credentials, and unsupported requests.
- Route actions through the same executors used by the local launcher.

### Phase 3 — Learned shortcuts

- Persist reusable intents and validated workflows after successful execution.
- Match familiar requests locally before calling the model.
- Add a simple interface to manage learned shortcuts.
- Demonstrate that a repeated learned request can execute without an LLM call.
- Evaluate more advanced matching and generated skills only when needed.

### Phase 4 — Pack delivery and updates

- Integrate the selected official/community plugins.
- Implement tested GitHub release updates and recovery.
- Verify settings and learned state survive upgrades.
- Investigate supported integration with Omarchy updates.
- Test on the target laptop, including battery use and suspend/resume.

## First-session brief for Claude CLI

Start by reading this README and inspecting the repository and local Omarchy installation.

Then:

1. Report the verified plugin/lifecycle/configuration mechanisms and the main unknowns.
2. Propose the smallest architecture that fits those mechanisms.
3. Implement Phase 1 incrementally on the dedicated test account.
4. Document exact setup and verification commands once they are actually known to work.
5. Update this README as functionality becomes real, keeping planned and implemented features distinct.

Do not try to build every phase at once. Preserve the core vision: **very pink, easy to navigate, concise personal assistant, useful local shortcuts, and one maintainable plugin pack.**

## How we will know it works

- She can open apps and find everyday controls without terminal commands.
- Diva's interface feels cohesive and responds smoothly on the target hardware.
- Common supported actions still work without internet access.
- Repeated learned actions can avoid a model call.
- Personal settings and learned shortcuts survive a pack update.
- Install, update, failure recovery, and uninstall work on a clean test account.
- Another installation works without relying on files from my main account.
- The pack's dependencies and compatibility with the tested Omarchy version are documented.
