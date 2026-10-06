#!/bin/bash
# Load the proposed Diva module ONCE in the real config, rather than loading
# an installed copy and then the proposed copy (which masked unset errors).
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
cat >"$staging/config.lua" <<'LUA'
package.preload["hypr.diva"] = function() dofile(os.getenv("DIVA_TEST_LOOK")) end
local main = os.getenv("HOME") .. "/.config/hypr/hyprland.lua"
local existing = io.open(main, "r")
if existing then
  existing:close()
  dofile(main)
else
  dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
  require("default.hypr.omarchy")
end
if not package.loaded["hypr.diva"] then require("hypr.diva") end
LUA
DIVA_TEST_LOOK="$root/hypr/diva.lua" Hyprland --verify-config -c "$staging/config.lua" >"$staging/result.txt" 2>&1
if ! rg -q '^config ok$' "$staging/result.txt"; then
  cat "$staging/result.txt"
  exit 1
fi
printf 'Hyprland config: pass\n'
