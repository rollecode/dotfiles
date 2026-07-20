# claude-code

Claude Code configuration: a Code::Stats integration, a destructive command guard, a Tokyo Night theme, and the global instructions Claude reads at session start.

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
* `require-permission-destructive.sh`, the destructive command guard, with `-test.sh` and `.cases.txt` alongside it
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

## Destructive command guard

`require-permission-destructive.sh` is a `PreToolUse` hook that inspects every Bash command before it runs. Auto mode already screens destructive actions, but it does so with an LLM classifier, so the same command can be allowed once and blocked the next time. This hook is the deterministic floor under that: it never varies, and unlike `permissions.deny` rules it still applies in `bypassPermissions`.

Denied outright, because there is nothing to undo:

* recursive `rm` aimed at `/`, `~`, `$HOME`, `/home/<user>`, `/usr`, `/etc` and friends, and any `--no-preserve-root`
* `mkfs`, `wipefs`, `fdisk`, `parted`, `dd of=/dev/*`, redirects into a block device
* `DROP DATABASE|SCHEMA|TABLE`, `TRUNCATE TABLE`, `DELETE FROM` with no `WHERE`, `dropdb`, `FLUSHALL`, `wp db reset`, `drush sql-drop`, `artisan migrate:fresh`
* `tmux kill-*`, `screen -X quit`, `systemctl stop|restart` on `user@`/`session-`/a display manager, `loginctl terminate-*`, `reboot`

Prompted, because the work is recoverable or the intent is often real: force and delete pushes, `reset --hard`, `clean -fd`, `branch -D`, `stash drop`, recursive `chown`/`chmod` on a system root.

Everything else passes untouched, so `rm -rf node_modules`, `DELETE ... WHERE id = 3` and `git push` keep running at full auto mode speed. The SQL rules only fire when a database client is present in the command, so grepping a migration for `DROP TABLE` is not mistaken for running it.

It matches on the command string, so a command assembled at runtime (`$(echo rm) -rf /`) gets through. It guards against accidents and classifier misses, not against someone trying to defeat it.

`./require-permission-destructive-test.sh` runs the cases in `require-permission-destructive.cases.txt` and asserts each one's decision.

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

`settings.json` also sets `verbose`, `alwaysThinkingEnabled` and `showThinkingSummaries`. Verbose is a persisted setting, not just the `Ctrl+O` toggle, so full tool output is shown instead of truncated summaries. `alwaysThinkingEnabled` only governs whether the model thinks, not whether you see it: with it on but `showThinkingSummaries` absent, thinking happens invisibly, which is what made this machine look like it had no thinking at all. `showThinkingSummaries` defaults to off and is the one that puts the thinking in the conversation and the `Ctrl+O` transcript. Note that on subscription plans the API returns summarised thinking, not raw reasoning, so there is a ceiling to this no setting can lift.

`effortLevel` is `high`, which is how much the model is allowed to think in the first place.
