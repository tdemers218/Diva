# Diva

An Omarchy plugin pack that girlifies the operating system. Includes **Diva**, a personal girly assistant to make everyday navigation simple.

> **Status: planning / pre-implementation.** This README is the project brief and starting point for Claude CLI. Features below are goals, not claims of working functionality. Suggested architecture and milestones are implementation proposals, not a finished specification.

## The goal

Diva is a personalized Omarchy experience being built for my girlfriend: cute, very pink, approachable, and usable by someone who is not familiar with computers.

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

