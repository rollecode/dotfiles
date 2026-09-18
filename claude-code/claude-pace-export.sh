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
#
# One report per Claude profile. CLAUDE_CONFIG_DIR swaps the whole account, and
# two accounts have different weekly allowances and different reset clocks, so
# their ledgers are separate and their verdicts are separate. A reader that
# cannot tell which account a number belongs to cannot act on it.
set -uo pipefail

PACE_PY="${PACE_PY:-$HOME/.claude/claude-pace.py}"
ALERT_PY="${ALERT_PY:-$HOME/.claude/claude-pace-alert.py}"
OUT_DIR="${CLAUDE_PACE_EXPORT_DIR:-$HOME/.claude/pace}"
PROFILES_JSON="${CLAUDE_PACE_PROFILES:-$OUT_DIR/profiles.json}"

[ -f "$PACE_PY" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

mkdir -p "$OUT_DIR" 2>/dev/null || exit 0

# Defaults so a fresh machine works with no config: the directory names the
# profile, and the plan label stays blank until profiles.json supplies one. A
# blank label is honest; a guessed one is not.
default_profiles() {
  cat <<EOF
[
  {"name": "personal", "dir": "$HOME/.claude", "label": ""},
  {"name": "work", "dir": "$HOME/.claude-work", "label": ""}
]
EOF
}

if [ -f "$PROFILES_JSON" ]; then
  PROFILES=$(cat "$PROFILES_JSON")
else
  PROFILES=$(default_profiles)
fi

# Write via temp files so a reader never catches a half-written report.
emit() {
  local args="$1" dest="$2"
  if python3 "$PACE_PY" $args > "$dest.tmp" 2>/dev/null; then
    mv "$dest.tmp" "$dest" 2>/dev/null
    return 0
  fi
  rm -f "$dest.tmp" 2>/dev/null
  return 1
}

INDEX_PARTS=()

while IFS=$'\t' read -r NAME DIR LABEL; do
  [ -n "$NAME" ] || continue
  LEDGER="$DIR/usage-pace.jsonl"
  # No ledger means that seat has never been used on this machine. Skip it
  # rather than publish a report full of zeroes that reads like a dry week.
  [ -s "$LEDGER" ] || continue

  export CLAUDE_PACE_LEDGER="$LEDGER"
  export CLAUDE_PACE_LATEST="$DIR/usage-pace-latest.json"

  emit "--json" "$OUT_DIR/report-$NAME.json" || continue
  emit "" "$OUT_DIR/report-$NAME.txt"
  emit "--oneline" "$OUT_DIR/oneline-$NAME.txt"

  # Stamp the identity onto the report itself, so nothing downstream has to
  # infer which account a percentage belongs to from a filename.
  NAME="$NAME" DIR="$DIR" LABEL="$LABEL" \
  python3 - "$OUT_DIR/report-$NAME.json" <<'PY'
import json, os, sys
p = sys.argv[1]
try:
    with open(p, encoding="utf-8") as fh:
        d = json.load(fh)
except Exception:
    raise SystemExit(0)
d["profile"] = os.environ["NAME"]
d["profile_dir"] = os.environ["DIR"]
d["label"] = os.environ.get("LABEL") or ""
tmp = p + ".tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(d, fh)
os.replace(tmp, p)
PY

  INDEX_PARTS+=("$OUT_DIR/report-$NAME.json")

  # The personal seat keeps the unsuffixed filenames, because readers that
  # predate multi-profile support still look for them.
  if [ "$NAME" = "personal" ]; then
    cp "$OUT_DIR/report-$NAME.json" "$OUT_DIR/report.json" 2>/dev/null
    cp "$OUT_DIR/report-$NAME.txt" "$OUT_DIR/report.txt" 2>/dev/null
    cp "$OUT_DIR/oneline-$NAME.txt" "$OUT_DIR/oneline.txt" 2>/dev/null
  fi
done < <(printf '%s' "$PROFILES" | python3 -c '
import json, sys
try:
    rows = json.load(sys.stdin)
except Exception:
    rows = []
for r in rows:
    print("\t".join([r.get("name",""), r.get("dir",""), r.get("label","")]))
')

unset CLAUDE_PACE_LEDGER CLAUDE_PACE_LATEST

# One file carrying every seat, so a reader gets the whole picture in one read
# and can never report one account's numbers under another's name.
if [ ${#INDEX_PARTS[@]} -gt 0 ]; then
  python3 - "$OUT_DIR/reports.json" "${INDEX_PARTS[@]}" <<'PY'
import json, os, sys
dest, parts = sys.argv[1], sys.argv[2:]
out = []
for p in parts:
    try:
        with open(p, encoding="utf-8") as fh:
            out.append(json.load(fh))
    except Exception:
        continue
tmp = dest + ".tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(out, fh)
os.replace(tmp, dest)
PY
fi

# Alert from the timer too, so an escalation is still caught during stretches
# with no Claude Code session open to drive the recorder.
[ -f "$ALERT_PY" ] && python3 "$ALERT_PY" >/dev/null 2>&1 || true

exit 0
