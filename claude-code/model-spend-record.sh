#!/bin/bash
# model-spend-record.sh - track ongoing monthly $ spend for non-Anthropic backends
# that have no usable balance/spend API (Qwen/DashScope has none reachable with a
# plain bearer key; DeepSeek's /user/balance gives remaining balance, not spend).
#
# Reads a statusline payload on stdin (same payload the statusline pipes to
# usage-pace-record.sh). Uses context_window.total_input_tokens/total_output_tokens,
# which are cumulative FOR THE SESSION, diffed against a per-session snapshot to
# get the incremental tokens since the last render, then priced at the flat
# input/output rate below and added to a running per-provider monthly total.
#
# Caveat: total_input_tokens does not break out cache-read vs full-price input,
# so this prices all input at the full rate. Cache hits are cheaper in reality,
# so this OVERESTIMATES spend, not under - the safer direction for a "how much
# have I burned" number. Treat it as an upper bound, not a bill.
#
# Called from the statusline on every render, backgrounded, so it must be cheap
# and silent - same discipline as usage-pace-record.sh.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null) || exit 0
[ -n "$INPUT" ] || exit 0

MODEL=$(printf '%s' "$INPUT" | jq -r '.model.display_name // empty' 2>/dev/null)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$MODEL" ] && [ -n "$SESSION_ID" ] || exit 0

# Pricing is USD per token (per-million rate / 1e6), pulled from the same figures
# documented in claude-code/model-backends.sh. Only the models claudeds/claudeqwen
# actually default to are covered - an overridden DS_MODEL/QWEN_MODEL silently
# falls outside this table rather than tracking the wrong price.
PROVIDER=""
IN_RATE=""
OUT_RATE=""
case "$MODEL" in
  deepseek-v4-pro)   PROVIDER="deepseek"; IN_RATE="0.000000435"; OUT_RATE="0.00000087" ;;
  deepseek-v4-flash*) PROVIDER="deepseek"; IN_RATE="0.00000014";  OUT_RATE="0.00000028" ;;
  qwen3.8-max)        PROVIDER="qwen";     IN_RATE="0.000002";    OUT_RATE="0.000006" ;;
  qwen3.6-flash)       PROVIDER="qwen";     IN_RATE="0.00000019";  OUT_RATE="0.00000113" ;;
  *) exit 0 ;;
esac

TOTAL_IN=$(printf '%s' "$INPUT" | jq -r '.context_window.total_input_tokens // 0' 2>/dev/null)
TOTAL_OUT=$(printf '%s' "$INPUT" | jq -r '.context_window.total_output_tokens // 0' 2>/dev/null)
case "$TOTAL_IN" in ''|*[!0-9]*) TOTAL_IN=0 ;; esac
case "$TOTAL_OUT" in ''|*[!0-9]*) TOTAL_OUT=0 ;; esac

STATE_DIR="$HOME/.claude/spend"
mkdir -p "$STATE_DIR" 2>/dev/null
SNAPSHOT="$STATE_DIR/session-${SESSION_ID}.json"
MONTHLY="$STATE_DIR/monthly-${PROVIDER}.json"
LOCKDIR="$STATE_DIR/.${PROVIDER}.lock.d"

LAST_IN=0
LAST_OUT=0
if [ -s "$SNAPSHOT" ]; then
  LAST_IN=$(jq -r '.in // 0' "$SNAPSHOT" 2>/dev/null); LAST_IN=${LAST_IN:-0}
  LAST_OUT=$(jq -r '.out // 0' "$SNAPSHOT" 2>/dev/null); LAST_OUT=${LAST_OUT:-0}
fi

DELTA_IN=$(( TOTAL_IN > LAST_IN ? TOTAL_IN - LAST_IN : 0 ))
DELTA_OUT=$(( TOTAL_OUT > LAST_OUT ? TOTAL_OUT - LAST_OUT : 0 ))

# Always refresh the snapshot, even with a zero delta (dedupe, cheap).
printf '{"in":%s,"out":%s}\n' "$TOTAL_IN" "$TOTAL_OUT" > "$SNAPSHOT.tmp" 2>/dev/null && mv "$SNAPSHOT.tmp" "$SNAPSHOT" 2>/dev/null

[ "$DELTA_IN" -gt 0 ] || [ "$DELTA_OUT" -gt 0 ] || exit 0

COST=$(awk -v i="$DELTA_IN" -v o="$DELTA_OUT" -v ir="$IN_RATE" -v or_="$OUT_RATE" 'BEGIN { printf "%.6f", (i*ir)+(o*or_) }')
MONTH=$(date '+%Y-%m')

# Same atomic mkdir lock as usage-pace-record.sh (no flock on macOS).
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  LOCK_AGE=$(( $(date +%s) - $(stat -f %m "$LOCKDIR" 2>/dev/null || stat -c %Y "$LOCKDIR" 2>/dev/null || echo 0) ))
  [ "$LOCK_AGE" -ge 30 ] || exit 0
  rmdir "$LOCKDIR" 2>/dev/null
  mkdir "$LOCKDIR" 2>/dev/null || exit 0
fi
trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

PREV_MONTH=""
PREV_TOTAL="0"
if [ -s "$MONTHLY" ]; then
  PREV_MONTH=$(jq -r '.month // empty' "$MONTHLY" 2>/dev/null)
  PREV_TOTAL=$(jq -r '.total // 0' "$MONTHLY" 2>/dev/null)
fi
[ "$PREV_MONTH" = "$MONTH" ] || PREV_TOTAL="0"

NEW_TOTAL=$(awk -v a="$PREV_TOTAL" -v b="$COST" 'BEGIN { printf "%.6f", a+b }')
printf '{"month":"%s","total":%s}\n' "$MONTH" "$NEW_TOTAL" > "$MONTHLY.tmp" 2>/dev/null && mv "$MONTHLY.tmp" "$MONTHLY" 2>/dev/null
