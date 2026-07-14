# claude-code

Claude Code configuration: a Code::Stats integration, a Tokyo Night theme, and the global instructions Claude reads at session start.

## Code::Stats

Posts a pulse to Code::Stats every time Claude edits or writes a file in a programming language you've configured. Modelled on the official Code::Stats Atom and Sublime plugins.

## What gets sent

For every `Edit`, `Write`, or `NotebookEdit` Claude makes on a file whose extension is in the language table, this hook posts:

```json
{
  "coded_at": "2026-06-13T01:23:45+03:00",
  "xps": [{"language": "Python", "xp": 12}]
}
```

That's it. No file path, no project name, no file content, no surrounding context, only `(coded_at, language, xp)`. Matches the wire payload of the official Code::Stats plugins.

If the file's extension isn't in the table, the hook drops the event silently with no pulse and no local log line. New private projects need no configuration to be safe by default, because the only data that can cross the network is the language name looked up from a closed table.

## Files

* `codestats-hook.py`, the hook script, pure stdlib Python 3.9+
* `secrets.sh.example`, copy to `secrets.sh` and fill in `CODESTATS_API_KEY`, or set the env var directly
* `settings.json`, Claude Code settings template registering the hook

## Install

1. Get your API key at `https://codestats.net/my/machines`
2. `cp secrets.sh.example secrets.sh` and paste your key
3. Link the hook into your Claude Code config:

```sh
mkdir -p ~/.claude/hooks
ln -s "$(pwd)/codestats-hook.py" ~/.claude/hooks/codestats-hook.py
```

4. Merge the snippet from `settings.json` into your `~/.claude/settings.json`
5. Edit a `.py` or `.ts` file with Claude, `tail -f ~/.claude/codestats-hook.log` should show a pulse entry

## Adding a new language

Open `codestats-hook.py`, add one entry to `EXTENSION_LANGUAGE`:

```python
"nim": "Nim",
```

That's the only maintenance.

## user-memory.md

Symlinked to `~/.claude/CLAUDE.md`, so it loads in every session on every machine. It asks Claude to explain implementation choices as it works, to give the reasoning behind each edit rather than narrating the diff back at you, and to always keep a task list. It is deliberately not named `CLAUDE.md` in this repo, because a file with that name inside `claude-code/` would be picked up as directory-scoped instructions whenever you worked in this folder.

## Tokyo Night theme for the TUI

`themes/tokyonight.json` is symlinked to `~/.claude/themes/tokyonight.json`. Select it with `/theme`, it live-reloads without a restart. It repaints the accent, the inline diff colours, the subagent colours and the usage meter, so nothing in the interface is left on the stock accent.

Claude Code has no colour token for thinking text. The documented tokens cover the accent, text shades, status colours and diffs, but reasoning output is simply de-emphasised secondary text, which is `inactive` and `subtle`. Both are set to purple here, so thinking comes out purple whichever one drives it. The cost is that hints, timestamps and faint borders go purple too, which on this palette reads as intentional.

## Display settings

`settings.json` also sets `verbose` and `alwaysThinkingEnabled`. Verbose is a persisted setting, not just the `Ctrl+O` toggle, so the detailed transcript, the thinking blocks and the task list are shown without pressing anything. Note that on subscription plans the API returns summarised thinking, not raw reasoning, so there is a ceiling to this no setting can lift.
