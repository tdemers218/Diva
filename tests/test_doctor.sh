#!/bin/bash
# Diva's diagnosis against a pretend machine: what is switched off on purpose
# is a problem only when the complaint is about that very thing.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lab=$(mktemp -d)
trap 'rm -rf "$lab"' EXIT
mkdir -p "$lab/bin" "$lab/state/diva"
stub() { printf '#!/bin/bash\n%s\n' "$2" >"$lab/bin/$1"; chmod +x "$lab/bin/$1"; }
stub nmcli 'echo "${LAB_NET:-full}"'
stub systemctl '[[ " $* " == *" is-active "* && " $* " == *" --quiet "* ]] && exit "${LAB_AUDIO:-0}"; echo active'
stub omarchy-shell 'exit 0'
stub omarchy 'echo "[{\"id\":\"io.github.tdemers218.diva\",\"enabled\":true}]"'
stub omarchy-audio-output-sink 'echo speakers'
stub df 'printf "Use%%\n 40%%\n"'
export PATH="$lab/bin:$PATH" XDG_STATE_HOME="$lab/state" XDG_CONFIG_HOME="$lab/config"
look() { DIVA_STATE_FAKE="$1" "$root/plugin/bin/diva-doctor" inspect "${2:-}"; }
expect() { [[ $(jq -c "$2" <<<"$1") == "$3" ]] || { echo "doctor: $4: $(jq -c "$2" <<<"$1"), expected $3" >&2; exit 1; }; }
fine='{"volume":50,"muted":false,"wifi":true,"network":"Maison","bluetooth":true}'
quiet='{"volume":50,"muted":true,"wifi":true,"network":"Maison","bluetooth":false}'

r=$(look "$fine"); expect "$r" '[.problems, .choices, .elsewhere]' '[[],[],[]]' "healthy machine"
# Muted, Bluetooth off, and no complaint about either: choices, not problems.
r=$(look "$quiet"); expect "$r" '.problems' '[]' "choices are not faults"; expect "$r" '.choices | length' '2' "both listed as choices"
r=$(look "$quiet" network); expect "$r" '.problems' '[]' "unrelated complaint leaves them alone"
# The complaint is about sound: muted is the problem; Bluetooth stays her choice.
r=$(look "$quiet" sound); expect "$r" '.problems' '["le son est coupé"]' "muted is the fault for a sound complaint"
expect "$r" '.choices' '["le Bluetooth est éteint"]' "bluetooth still a choice"
r=$(look "$quiet" sound,bluetooth); expect "$r" '.problems | length' '2' "both, when both are asked about"
# Bluetooth switched off by the battery policy says so.
echo '{"level":2,"cuts":{"bluetooth":"on"}}' >"$lab/state/diva/power.json"
r=$(look "$quiet"); expect "$r" '.choices | map(test("économie de batterie")) | any' 'true' "battery policy named"
rm "$lab/state/diva/power.json"
# A real fault is a problem whatever is asked, or a remark when elsewhere.
r=$(LAB_AUDIO=3 look "$fine"); expect "$r" '.problems' '["le système de son ne tourne pas"]' "fault without a complaint"
r=$(LAB_AUDIO=3 look "$fine" network); expect "$r" '[.problems, .elsewhere]' '[[],["le système de son ne tourne pas"]]' "fault elsewhere is a remark"
r=$(LAB_NET=limited look "$fine" network); expect "$r" '.problems | length' '1' "network fault for a network complaint"
printf 'Diagnosis: pass\n'
