# Put every interactive shell inside tmux, so anything started here can be
# reached later from another machine. Forgetting to do this by hand is the whole
# problem: a Claude session left in a bare local terminal is unreachable from a
# phone, and Remote Control cannot help when ANTHROPIC_BASE_URL is not Anthropic.
#
# SSH logins share one session called main, so reconnecting lands where you left.
# Local terminals each get their own session named after the directory, so two
# windows never mirror each other. No exec: if tmux fails you still get a shell.
if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
  if [[ -n "$SSH_CONNECTION" ]]; then
    tmux new-session -A -s main
  else
    _tmux_name=${PWD##*/}
    _tmux_name=${_tmux_name//[^a-zA-Z0-9_-]/_}
    [[ -z $_tmux_name ]] && _tmux_name=shell
    if tmux has-session -t "=$_tmux_name" 2>/dev/null; then
      _tmux_n=2
      while tmux has-session -t "=${_tmux_name}-${_tmux_n}" 2>/dev/null; do
        _tmux_n=$((_tmux_n + 1))
      done
      _tmux_name="${_tmux_name}-${_tmux_n}"
    fi
    tmux new-session -s "$_tmux_name"
    unset _tmux_name _tmux_n
  fi
fi
