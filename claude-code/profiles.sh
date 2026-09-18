#!/bin/bash
# Claude Code under a second account on the same machine.
#
# CLAUDE_CONFIG_DIR swaps the whole profile, not only the login: credentials,
# transcripts, settings and MCP servers all live under it. That is what keeps a
# work seat and a personal seat apart on one machine, and why /login inside one
# session cannot disturb the claudes running under the other.
#
# It is not remembered by a session, so it has to be set on every launch. Forget
# it and `claude --resume` in the same directory lists the personal sessions and
# the work ones look lost; they are not, they are in the other profile. Sessions
# live at $CLAUDE_CONFIG_DIR/projects/<slugified-cwd>/<uuid>.jsonl, so resuming
# one needs the same profile and the same working directory it was started in.
#
# Flags pass through, so cw --resume, cw -c and cw --resume <uuid> all behave as
# they do with plain claude.

# Dude's team seat (ai@dude.fi work context, Digitoimisto Dude Oy).
cw() {
  CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude "$@"
}
