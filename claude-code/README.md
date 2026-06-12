# claude-code

Code::Stats integration for Claude Code.

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
