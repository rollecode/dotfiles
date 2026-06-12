# claude-code

[Code::Stats](https://codestats.net) integration for [Claude Code](https://claude.com/claude-code).

Posts a pulse to Code::Stats every time Claude Code edits or writes a file
in a programming language you've configured.

## What gets sent

For every `Edit`, `Write`, or `NotebookEdit` Claude makes on a file whose
extension is in the language table, this hook posts:

```json
{
  "coded_at": "2026-06-13T01:23:45+03:00",
  "xps": [{"language": "Python", "xp": 12}]
}
```

That's it. No file path, no project name, no file content, no surrounding
context — only `(coded_at, language, xp)`. This matches the wire payload of
the official Code::Stats plugins for Atom, Sublime Text, VS Code etc.

If the file's extension isn't in the table the hook drops the event
silently — no pulse, no local log line. So new private projects need no
configuration to be safe by default.

## Files

- `codestats-hook.py` — the hook script. Pure stdlib Python 3.9+.
- `secrets.sh.example` — copy to `secrets.sh` and fill in `CODESTATS_API_KEY`.
  Alternatively set the environment variable directly.
- `settings.json` — Claude Code settings template registering the hook.

## Install

1. Get your API key at https://codestats.net/my/machines
2. `cp secrets.sh.example secrets.sh` and paste your key
3. Copy the settings into your Claude config:
   ```sh
   mkdir -p ~/.claude/hooks
   ln -s "$(pwd)/codestats-hook.py" ~/.claude/hooks/codestats-hook.py
   cat settings.json >> ~/.claude/settings.json  # merge into your settings
   ```
4. Edit a `.py` or `.ts` file with Claude — `tail -f ~/.claude/codestats-hook.log` should show a pulse entry.

## Adding a new language

Open `codestats-hook.py`, add one entry to `EXTENSION_LANGUAGE`:

```python
"nim": "Nim",
```

That's the only maintenance.

## Why the previous Bash hook was retired

The `codestats-hook.sh` shipped before 2.1.19 had a `get_language()`
fallback that uppercased the entire file path when an extension was
missing (LICENSE, Caddyfile, README without `.md`, etc.). That string
became the "language" value in the pulse. Code::Stats then displayed
your file paths as language names on your public profile. Replaced
entirely with the Python version above, which has no
unknown-extension fallback by design — the bug class is structurally
impossible.
