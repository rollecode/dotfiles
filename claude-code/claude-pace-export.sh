#!/bin/bash
# claude-pace-export.sh - publish the current pace verdict, and alert on changes.
#
# ~/.claude is private to the host, but other things need the verdict: nanoclaw
# reads it from inside a container, and the notice hook wants it without paying
# for a recompute on every prompt. So the report is exported to ~/.claude/pace/,
# which is the only directory mounted into agent containers.
#
# Pace shifts as the clock moves even when nothing is being spent - being idle on
# Tuesday is exactly when "you are behind, go use it" matters - so this runs on a
# timer rather than only when a session is live.
set -uo pipefail

PACE_PY="${PACE_PY:-$HOME/.claude/claude-pace.py}"
ALERT_PY="${ALERT_PY:-$HOME/.claude/claude-pace-alert.py}"
OUT_DIR="${CLAUDE_PACE_EXPORT_DIR:-$HOME/.claude/pace}"

[ -f "$PACE_PY" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p "$OUT_DIR" 2>/dev/null || exit 0

# Write via temp files so a reader never catches a half-written report.
emit() {
  local args="$1" dest="$2"
  if python3 "$PACE_PY" $args > "$dest.tmp" 2>/dev/null; then
    mv "$dest.tmp" "$dest" 2>/dev/null
  else
    rm -f "$dest.tmp" 2>/dev/null
  fi
}

emit "--json" "$OUT_DIR/report.json"
emit "" "$OUT_DIR/report.txt"
emit "--oneline" "$OUT_DIR/oneline.txt"

# Alert from the timer too, so an escalation is still caught during stretches
# with no Claude Code session open to drive the recorder.
[ -f "$ALERT_PY" ] && python3 "$ALERT_PY" >/dev/null 2>&1 || true

exit 0
