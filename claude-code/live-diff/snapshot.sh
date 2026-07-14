#!/usr/bin/env bash
# PreToolUse(Edit|Write|NotebookEdit): stash the file as it was before Claude touched it,
# so the post hook can show a true per-edit diff even outside a git repo.
set -uo pipefail
. "$HOME/.claude/live-diff/lib.sh"

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty')
session=$(printf '%s' "$payload" | jq -r '.session_id // "nosession"')
[ -n "$file" ] || exit 0

snapdir=$(cc_snapdir "$session")
mkdir -p "$snapdir"
key=$(cc_hash_path "$file")

if [ -f "$file" ]; then
  cp "$file" "$snapdir/$key" 2>/dev/null
else
  # New file: empty baseline, so the diff renders the whole file as added.
  : > "$snapdir/$key"
fi

exit 0
