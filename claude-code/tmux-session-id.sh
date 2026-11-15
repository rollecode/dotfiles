#!/bin/bash
# UserPromptSubmit hook: remember which conversation each tmux session holds,
# so tmux-layout-restore can bring it back with claude --resume <id>.
[ -n "$TMUX_PANE" ] || exit 0

id=$(jq -r '.session_id // empty' 2>/dev/null)
[ -n "$id" ] || exit 0

name=$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null)
[ -n "$name" ] || exit 0

dir="$HOME/.local/state/tmux-restore/claude"
mkdir -p "$dir"
printf '%s\n' "$id" > "$dir/$name.tmp" && mv "$dir/$name.tmp" "$dir/$name"
exit 0
