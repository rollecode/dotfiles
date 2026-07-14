#!/usr/bin/env bash
# The viewer. Run this in a second pane — any terminal, any multiplexer, or a bare ssh session.
#
#   ccwatch            follow the live stream
#   ccwatch --split    split the current tmux pane and follow it there (tmux only)
#
set -uo pipefail
. "$HOME/.claude/live-diff/lib.sh"

log=$(cc_log)
mkdir -p "$(dirname "$log")"
[ -f "$log" ] || : > "$log"

if [ "${1:-}" = "--split" ]; then
  if [ -n "${TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then
    tmux split-window -h "$0"
    exit 0
  fi
  echo "--split needs tmux and an active tmux session; falling back to inline." >&2
fi

printf '\033[2mwatching %s — Ctrl-C to stop\033[0m\n' "$log"
exec tail -n +1 -f "$log"
