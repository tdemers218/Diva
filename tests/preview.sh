#!/bin/bash
# A separate offscreen Quickshell instance; never replaces the live shell.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/runtime"
chmod 700 "$staging/runtime"
ln -s "$root/plugin" "$staging/plugin"
ln -s "${OMARCHY_PATH:-/usr/share/omarchy}/shell/Commons" "$staging/Commons"
ln -s "${OMARCHY_PATH:-/usr/share/omarchy}/shell/Ui" "$staging/Ui"
cp "$root/tests/preview.qml" "$staging/shell.qml"
env -u QT_QPA_PLATFORMTHEME -u WAYLAND_DISPLAY -u HYPRLAND_INSTANCE_SIGNATURE XDG_RUNTIME_DIR="$staging/runtime" QT_QPA_PLATFORM=offscreen QT_QUICK_CONTROLS_STYLE=Basic qs -p "$staging/shell.qml" >"$staging/preview.log" 2>&1
if rg 'Failed to load|Error loading|ReferenceError|TypeError|Error:|file:.*(Error|Warning)' "$staging/preview.log"; then
  cat "$staging/preview.log"
  exit 1
fi
printf 'Preview rendered: /tmp/diva-{wifi,bluetooth,controls,appearance,password,overview}.png\n'
