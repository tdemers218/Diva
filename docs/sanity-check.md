# Diva sanity check — 2026-10-05

## Confirmed overview failure

The running shell's readable log at
`/run/user/1001/quickshell/by-id/5868lolgmt/log.log` showed that the installed
`OverviewView.qml` still contained `Unexpected token ';'` at line 75.
This prevented `Desktop.qml` and its parent `Companion.qml` from loading. Neither
the hot edge nor `diva.desktop` gesture calls could work with that service absent.
The source had already been corrected, but an installation at 20:07:33 captured
an earlier, unfinished version. Twelve installed plugin files differed from the
current source when this audit started. This establishes an installation/cache
mismatch; it does not establish which editor caused any particular concurrent edit.

## Corrections made

- Synchronized the validated plugin files and Diva Hyprland module to the user
  installation, with a backup in
  `~/.local/state/diva/backups/sanity-20261005-203458/`.
- Completed the workspace-widget migration while retaining its complete inline
  entry in the installation record for uninstall. Other layout entries and the
  screensaver installation state were retained.
- Removed unconditional gesture `unset` calls. Fresh config verification revealed
  that Hyprland reports an error when the gesture does not exist. The earlier
  verification loaded the installed and proposed modules together, masking this
  problem. The new regression check substitutes the proposed module and loads it
  exactly once in the real config.
- Added independent `Service.qml` loaders for the desktop and companion. A failure
  in one component no longer makes the other unavailable.
- Added `diva.desktop status` and checks for an unresponsive desktop service and
  source/installed-code divergence to `bin/diva status`.
- Added offscreen QML validation before installation copies files into the live
  plugin. Generated Python caches are excluded from installation and comparison.
- Retained the source's corrected page binding so the Wi-Fi/Bluetooth/Son/Fond
  tabs actually change the shared ControlPage loader's section.
- Delayed Bluetooth outcome reporting until the native BlueZ properties have
  settled, rather than immediately reporting a false failure after command exit.
  Pending actions remain disabled during this settling interval.
- Sorted Wi-Fi networks by connected, remembered, then signal strength, and stopped
  treating every failed network operation as a password-entry problem.
- Fixed dock grouping for window classes that collide with JavaScript prototype
  names; added a regression test.

## Verification and current live state

54 QML tests pass, plus isolated wallpaper and install/update/uninstall tests,
offscreen visual/compilation checks for supported components, and fresh Hyprland
configuration verification. The current installed code matches the source, and
verification of the actual installed `hyprland.lua` reports `config ok`.

The live log confirms file-change notifications, but its QML engine still reports
the cached old Companion/Overview error and a directory-cache error for the newly
added Service.qml. A fresh shell process is needed. This agent cannot access the
Wayland, Quickshell IPC, or D-Bus sockets; reload/rescan attempts were denied by
socket access restrictions. The shell is running despite the wrapper's misleading
“not running” message. Run `omarchy restart shell` in the desktop terminal, then
`omarchy-shell diva.desktop status` to confirm registration. Actual pointer entry,
touchpad gestures, window capture, and radio operations remain live-session checks.

## Native control styling pass

The four native pages use a consistent settings composition: quiet navigation,
compact connection controls beside grouped device lists, aligned labels and
secondary actions, subtle connected-state highlights, and slim volume/brightness
controls. At narrow widths the sections stack. Audio gives the output panel more
space than the microphone; appearance pairs screen controls with a smaller style
panel and an adaptive wallpaper gallery. Password entry and confirmed forgetting
remain within the native pages.

Populated offscreen previews now include the surrounding menu surface and cover
all four pages, password entry, and narrow/wide menus. The 54 QML tests and isolated
install, wallpaper, and Hyprland checks pass. This is a visual pass over the
existing service integration: enterprise Wi-Fi profile creation, Bluetooth PIN
confirmation, and hardware battery details remain separate backend work. Actual
radio operations still require the desktop session. Other shared edits were
retained; no commit or reset of the checkout was performed.
