#!/bin/bash
# The action runner's three verdicts, without a desktop: failed, launched,
# and (for a state it can read) verified.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
run() { "$root/plugin/bin/diva-run" "$@"; }
expect() { [[ $(jq -r .state <<<"$1") == "$2" ]] || { echo "run: $3: $1, expected $2" >&2; exit 1; }; }
expect "$(run none -- false)" failed "a command that fails"
expect "$(run none -- true)" launched "a command that succeeds, nothing to observe"
expect "$(run none -- sleep 4)" launched "a command still running"
expect "$(run none -- /nonexistent/command)" failed "a command that does not exist"
expect "$(run unknown-check -- sh -c 'exit 3')" failed "an unknown check still reads the exit code"
expect "$(run none)" failed "nothing to run"
[[ $(run none -- false | jq -c '[.ok, .verified]') == '[false,true]' ]] || { echo "run: failure must be ok:false verified:true" >&2; exit 1; }
printf 'Action runner: pass\n'
