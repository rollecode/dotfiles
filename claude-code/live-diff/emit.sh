#!/usr/bin/env bash
# PostToolUse(Edit|Write|NotebookEdit): diff the pre-edit snapshot against the file on disk
# and append it to the live stream. Renders through delta/bat if present, plain git colour if not.
set -uo pipefail
. "$HOME/.claude/live-diff/lib.sh"

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')
session=$(printf '%s' "$payload" | jq -r '.session_id // "nosession"')
tool=$(printf '%s' "$payload" | jq -r '.tool_name // "?"')
[ -n "$file" ] && [ -f "$file" ] || exit 0

snapdir=$(cc_snapdir "$session")
key=$(cc_hash_path "$file")
before="$snapdir/$key"
[ -f "$before" ] || before=/dev/null

log=$(cc_log)
mkdir -p "$(dirname "$log")"

rel="$file"
case "$file" in "$PWD"/*) rel="${file#"$PWD"/}" ;; esac

{
  printf '\n\033[1;36m┌─ %s \033[0;36m%s\033[0m \033[2m%s\033[0m\n' \
    "$tool" "$rel" "$(date '+%H:%M:%S')"

  if command -v delta >/dev/null 2>&1; then
    git diff --no-index --no-ext-diff "$before" "$file" 2>/dev/null | delta --paging=never
  else
    # --no-index works on arbitrary paths, inside a repo or not.
    git diff --no-index --no-ext-diff --color=always "$before" "$file" 2>/dev/null \
      | tail -n +5   # drop the noisy /tmp-vs-realpath header lines
  fi
} >> "$log"

exit 0
