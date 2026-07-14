#!/usr/bin/env bash
# SessionStart: start each session with a clean stream so the pane isn't an infinite scrollback.
set -uo pipefail
. "$HOME/.claude/live-diff/lib.sh"

log=$(cc_log)
mkdir -p "$(dirname "$log")"
: > "$log"
printf '\033[2m── new session · %s ──\033[0m\n' "$(date '+%Y-%m-%d %H:%M')" >> "$log"
exit 0
