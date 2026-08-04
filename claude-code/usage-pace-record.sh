#!/bin/bash
# usage-pace-record.sh - append Claude Code rate-limit samples to a local ledger.
#
# Reads a statusline payload on stdin. Claude Code is the only thing that knows
# the plan's live 5-hour and 7-day utilisation, and the statusline hook is the
# only place it hands that over (`.rate_limits`), so this is where the history
# has to be captured from.
#
# Ledger: ~/.claude/usage-pace.jsonl, one JSON object per sample:
#   {"ts":epoch,"w":weekly%,"h5":5h%,"wr":weekly_reset,"hr":5h_reset,"model":"id"}
# Snapshot: ~/.claude/usage-pace-latest.json (always the newest sample).
#
# Called from the statusline on every render, so it must be cheap and silent.
# A sample is only appended when a percentage or the model changed, or after
# HEARTBEAT_S, which keeps the file small while still capturing every transition
# needed to derive a burn rate.
set -uo pipefail

LEDGER="$HOME/.claude/usage-pace.jsonl"
LATEST="$HOME/.claude/usage-pace-latest.json"
LOCK="$HOME/.claude/.usage-pace.lock"
LOCKDIR="$HOME/.claude/.usage-pace.lock.d"
HEARTBEAT_S=600
MAX_LINES=5000

# BSD and GNU stat disagree on the mtime flag, and this script runs on both.
_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null) || exit 0
[ -n "$INPUT" ] || exit 0

SAMPLE=$(printf '%s' "$INPUT" | jq -c '
  (.rate_limits // {}) as $r
  | select(($r.seven_day.used_percentage != null) or ($r.five_hour.used_percentage != null))
  | {ts: (now | floor),
     w:  $r.seven_day.used_percentage,
     h5: $r.five_hour.used_percentage,
     wr: $r.seven_day.resets_at,
     hr: $r.five_hour.resets_at,
     model: (.model.id // "?")}' 2>/dev/null) || exit 0
[ -n "$SAMPLE" ] || exit 0

# Snapshot is cheap and always current; readers that only need "right now" use it.
printf '%s\n' "$SAMPLE" > "$LATEST.tmp" 2>/dev/null && mv "$LATEST.tmp" "$LATEST" 2>/dev/null

# Serialise the read-compare-append so concurrent sessions cannot interleave.
# flock does not ship with macOS, and the old unconditional call meant the
# `|| exit 0` fired on every render there - the snapshot was written but the
# ledger never was, so pace had no history to derive a burn rate from. Fall back
# to an atomic mkdir lock, reaping one older than a minute so a killed session
# cannot wedge the recorder permanently.
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK" 2>/dev/null || exit 0
  flock -n 9 2>/dev/null || exit 0
else
  if ! mkdir "$LOCKDIR" 2>/dev/null; then
    [ $(( $(date +%s) - $(_mtime "$LOCKDIR") )) -ge 60 ] || exit 0
    rmdir "$LOCKDIR" 2>/dev/null
    mkdir "$LOCKDIR" 2>/dev/null || exit 0
  fi
  trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT
fi

mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
LAST=$(tail -n 1 "$LEDGER" 2>/dev/null)

if [ -n "$LAST" ]; then
  CHANGED=$(jq -n --argjson a "$LAST" --argjson b "$SAMPLE" --argjson hb "$HEARTBEAT_S" '
    ($a.w != $b.w) or ($a.h5 != $b.h5) or ($a.model != $b.model)
    or (($b.ts - $a.ts) >= $hb)' 2>/dev/null)
  [ "$CHANGED" = "true" ] || exit 0
fi

printf '%s\n' "$SAMPLE" >> "$LEDGER" 2>/dev/null

# Prune without truncating in place, so a reader never sees a half-empty file.
LINES=$(wc -l < "$LEDGER" 2>/dev/null || echo 0)
if [ "${LINES:-0}" -gt "$MAX_LINES" ]; then
  tail -n "$MAX_LINES" "$LEDGER" > "$LEDGER.tmp" 2>/dev/null && mv "$LEDGER.tmp" "$LEDGER" 2>/dev/null
fi

# Real-time alerting. The recorder is the only thing that sees the percentage
# change the moment Claude Code reports it, so escalations are pushed from here
# rather than waited for on a cron. Throttled and backgrounded: this must never
# add latency to a status line render.
ALERT="$HOME/.claude/claude-pace-alert.py"
ALERT_STAMP="$HOME/.claude/.usage-pace-alert.stamp"
if [ -x "$ALERT" ] || [ -f "$ALERT" ]; then
  now_s=$(date +%s)
  last_s=0
  [ -f "$ALERT_STAMP" ] && last_s=$(_mtime "$ALERT_STAMP")
  if [ $(( now_s - last_s )) -ge 60 ]; then
    touch "$ALERT_STAMP" 2>/dev/null
    ( python3 "$ALERT" >/dev/null 2>&1 & ) 2>/dev/null
  fi
fi

exit 0
