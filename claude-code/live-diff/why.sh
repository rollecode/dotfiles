#!/usr/bin/env bash
# Lets Claude drop a one-line rationale into the same stream as the diffs, so the
# explanation lands next to the change it explains instead of scrolling past in the chat pane.
# Usage: why.sh "kept the retry in the caller so the transport stays stateless"
set -uo pipefail
. "$HOME/.claude/live-diff/lib.sh"

msg="$*"
[ -n "$msg" ] || exit 0

log=$(cc_log)
mkdir -p "$(dirname "$log")"
printf '\033[1;33m│ why \033[0m\033[33m%s\033[0m\n' "$msg" >> "$log"
exit 0
