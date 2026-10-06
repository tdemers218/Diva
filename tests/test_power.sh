#!/bin/bash
# Diva's battery policy against a pretend laptop: stand-in commands keep a
# brightness, a power profile and a Bluetooth switch in files, and the battery
# reading is given by DIVA_POWER_FAKE. Nothing on the real machine is touched.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lab=$(mktemp -d)
trap 'rm -rf "$lab"' EXIT
mkdir -p "$lab/bin" "$lab/config/diva"
stub() { printf '#!/bin/bash\n%s\n' "$2" >"$lab/bin/$1"; chmod +x "$lab/bin/$1"; }
stub brightnessctl 'echo "dev,backlight,0,$(cat "$LAB/brightness")%,100"'
stub omarchy-brightness-display 'for a; do [[ $a == *% ]] && echo "${a%\%}" >"$LAB/brightness"; done'
stub omarchy-brightness-keyboard 'echo "$2" >"$LAB/keyboard"'
stub hyprctl '[[ $1 == getoption ]] && echo "bool: false"; exit 0'
stub powerprofilesctl 'if [[ $1 == get ]]; then cat "$LAB/profile"; else echo "$2" >"$LAB/profile"; fi'
stub omarchy-bluetooth-power 'case $1 in is-on) [[ $(cat "$LAB/bluetooth") == on ]] ;; *) echo "$1" >"$LAB/bluetooth" ;; esac'
stub bluetoothctl 'exit 0'
stub sleep 'exit 0'
export LAB="$lab" PATH="$lab/bin:$PATH" XDG_STATE_HOME="$lab/state" XDG_CONFIG_HOME="$lab/config"
power() { DIVA_POWER_FAKE="$1" "$root/plugin/bin/diva-power" apply >/dev/null; }
at() { power "{\"onBattery\":true,\"percent\":$1,\"minutes\":${2:--1}}"; }
plugged() { power '{"onBattery":false,"percent":90}'; }
reset() { rm -rf "$lab/state"; echo "$1" >"$lab/brightness"; echo balanced >"$lab/profile"; echo on >"$lab/bluetooth"; echo on >"$lab/keyboard"; }
level() { jq -r .level "$lab/state/diva/power.json"; }
expect() { [[ $(cat "$lab/$1") == "$2" ]] || { echo "power: $3: $1 is $(cat "$lab/$1"), expected $2" >&2; exit 1; }; }
expect_level() { [[ $(level) == "$1" ]] || { echo "power: $2: level $(level), expected $1" >&2; exit 1; }; }

# The reported bug: 80 -> 65 at level 2 -> 40 at level 3 -> plugged in.
reset 80; at 45; expect brightness 65 "level 2 dims"; at 15; expect brightness 40 "level 3 caps"
expect profile power-saver "level 2 profile"; expect bluetooth off "level 2 bluetooth"; expect keyboard off "level 3 keyboard"
plugged; expect brightness 80 "plugged in after level 3"; expect profile balanced "profile back"; expect bluetooth on "bluetooth back"; expect keyboard restore "keyboard back"
expect_level 0 "plugged in"

# Down one level at a time.
reset 80; at 45; at 15; at 45; expect_level 2 "back to level 2"; expect brightness 65 "cap lifted, still dimmed"
at 90; expect_level 1 "back to level 1"; expect brightness 80 "dimming lifted"

# Straight to level 3, then plugged in.
reset 90; at 10; expect brightness 40 "straight to level 3"; plugged; expect brightness 90 "restored from level 3"

# A brightness she set herself in the meantime stays hers.
reset 80; at 45; at 15; echo 55 >"$lab/brightness"; plugged; expect brightness 55 "manual change kept"
reset 80; at 45; echo 70 >"$lab/brightness"; plugged; expect brightness 70 "manual change kept at level 2"

# A profile or Bluetooth she changed herself is not put back over her choice.
reset 80; at 45; echo performance >"$lab/profile"; plugged; expect profile performance "manual profile kept"

# A screen already dim is not dimmed further at level 2, and is still capped at 3.
reset 50; at 45; expect brightness 50 "no dimming under 60"; at 15; expect brightness 40 "capped"; plugged; expect brightness 50 "restored"

# An estimate wavering around a threshold does not flip levels.
reset 80; at 80 140; expect_level 2 "short estimate"; at 80 160; expect_level 2 "held just past the threshold"
at 80 200; expect_level 1 "released with margin"; at 52; expect_level 1 "above 50 from below stays 1"
at 50; expect_level 2 "at 50"; at 53; expect_level 2 "held at 53"; at 56; expect_level 1 "released at 56"
at 20; expect_level 3 "at 20"; at 24 50; expect_level 3 "held"; at 26 70; expect_level 2 "released"
printf 'Battery policy: pass\n'
