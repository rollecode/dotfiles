# claude-code

Claude Code configuration: a Code::Stats integration, and a live diff stream that shows every change as it happens.

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

## Live diff stream

Watch every change Claude makes, in a second pane, as it happens. Needs only `bash`, `git` and `jq`, so it works the same over SSH on a server as it does locally, in any terminal and any multiplexer.

Run the viewer in a second pane:

```sh
~/.claude/live-diff/watch.sh           # follow the stream
~/.claude/live-diff/watch.sh --split   # split the current tmux pane instead
```

Each `Edit`, `Write` or `NotebookEdit` appends a coloured per-edit diff, followed by a one-line rationale from Claude:

```
┌─ Edit src/auth.py 22:35:17
@@ -1,2 +1,4 @@
-def greet(name):
+def greet(name: str) -> str:
+    if not name:
+        raise ValueError("name required")
│ why raise instead of returning empty so callers cannot silently pass a blank name
```

How it works:

* `snapshot.sh`, a `PreToolUse` hook, copies the file before Claude touches it, so the diff is a true per-edit diff and works outside a git repo
* `emit.sh`, a `PostToolUse` hook, diffs the snapshot against the file on disk and appends it to the stream. Renders through `delta` if installed, plain `git diff` colour if not
* `why.sh` is called by Claude after each edit, per the instruction in `user-memory.md`, and puts the reasoning next to the change it explains
* `reset.sh`, a `SessionStart` hook, truncates the stream so the pane starts clean each session
* `lib.sh` holds the shared path and hashing helpers

## Diff theme

The stream is themed Tokyo Night, with purple hunk headers and purple keywords. `themes/tokyonight_night.tmTheme` is vendored from `folke/tokyonight.nvim`, so a server with no network still gets the theme.

`bat` is a hard dependency of the theme, not a nicety: delta loads a custom syntax theme only from bat's compiled cache, so `install.sh` installs `bat`, copies the theme into `$(bat --config-dir)/themes` and runs `bat cache --build`. Without `bat` the stream still works, it just falls back to delta's built-in themes. Without `delta` at all it falls back to plain `git diff` colour.

The palette lives at the top of `lib.sh` as `CC_TN_*` variables, so the colours have one source of truth. Flags are passed to delta explicitly rather than through a `[delta]` section in `~/.gitconfig`, so the stream looks the same on a machine whose gitconfig this repo does not control.

The stream lives at `~/.claude/live-diff-stream.log`, override with `CC_LIVE_LOG`. It is deliberately kept out of `~/.claude/live-diff/`, since that path is a symlink into this repo and the stream carries diffs of whatever you are editing at the time.

## user-memory.md

Symlinked to `~/.claude/CLAUDE.md`, so it loads in every session on every machine. It asks Claude to explain implementation choices as it works, to log the "why" of each edit into the live diff stream, and to always keep a task list. It is deliberately not named `CLAUDE.md` in this repo, because a file with that name inside `claude-code/` would be picked up as directory-scoped instructions whenever you worked in this folder.

## Display settings

`settings.json` also sets `verbose` and `alwaysThinkingEnabled`. Verbose is a persisted setting, not just the `Ctrl+O` toggle, so the detailed transcript, the thinking blocks and the task list are shown without pressing anything. Note that on subscription plans the API returns summarised thinking, not raw reasoning, so there is a ceiling to this no setting can lift.
