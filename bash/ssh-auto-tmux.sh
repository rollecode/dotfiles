# Attach (or create) a persistent tmux session on SSH logins only, so phone
# clients can drop and reconnect without losing the shell. No exec: if tmux
# fails you still land in a normal shell instead of being locked out.
#
# Source from ~/.bashrc, or append the block itself.
if [[ $- == *i* ]] && [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
  tmux new-session -A -s main
fi
