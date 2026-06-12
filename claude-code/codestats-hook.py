#!/usr/bin/env python3
"""
Code::Stats Claude Code hook, professional implementation.

Modelled on the official Code::Stats Atom and Sublime Text plugins:
  https://github.com/code-stats/code-stats-atom
  https://github.com/code-stats/code-stats-sublime

API spec (https://codestats.net/api-docs):
  POST https://codestats.net/api/my/pulses
  Header: X-API-Token: <key>
  Body:   {"coded_at": "<ISO 8601 with local TZ offset>",
           "xps": [{"language": "<name>", "xp": <int>}, ...]}

Where the official plugins read language from the editor's syntax highlighting
(Atom: grammar.name, Sublime: syntax file name), this hook fires from Claude
Code's PostToolUse for Edit/Write/NotebookEdit, with no editor context. We
detect language from a closed extension table whose keys are file extensions
and whose values are canonical Code::Stats language names. The structural
property: nothing about the file PATH or project ever leaves the script,
because the only string that ever crosses the network is the language name
looked up from the table. Adding a new language is one line in EXTENSION_LANGUAGE.

Behavioural details that match the official plugins:
  * X-API-Token auth header.
  * coded_at uses the user's local time with local UTC offset, colon form
    (e.g. 2026-06-13T01:23:45+03:00). Code::Stats docs require this.
  * User-Agent identifies the client.
  * 201 + {"ok":"Great success!"} is success; anything else is logged.
  * Failures never block the Claude tool call.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

VERSION = "1.0.0"
API_URL = "https://codestats.net/api/my/pulses"
USER_AGENT = f"claude-code-codestats/{VERSION}"
LOG_PATH = Path.home() / ".claude" / "codestats-hook.log"
API_KEY_ENV = "CODESTATS_API_KEY"
# Fallback for users who keep their key in a sourced shell file alongside
# this script (the original setup).
SECRETS_SH_FALLBACK = Path(__file__).resolve().parent / "secrets.sh"


# Closed extension to canonical Code::Stats language name.
# Anything not in this table is dropped silently — no fallback that could
# leak a path. To add a language: one line here.
EXTENSION_LANGUAGE: dict[str, str] = {
    "bash": "Bash",
    "c": "C",
    "cc": "C++",
    "cjs": "JavaScript",
    "cpp": "C++",
    "cs": "C#",
    "css": "CSS",
    "cxx": "C++",
    "dart": "Dart",
    "diff": "Diff",
    "elm": "Elm",
    "erl": "Erlang",
    "ex": "Elixir",
    "exs": "Elixir",
    "fish": "Fish",
    "go": "Go",
    "graphql": "GraphQL",
    "h": "C",
    "hpp": "C++",
    "hs": "Haskell",
    "html": "HTML",
    "java": "Java",
    "jl": "Julia",
    "js": "JavaScript",
    "json": "JSON",
    "jsx": "JavaScript JSX",
    "kt": "Kotlin",
    "less": "Less",
    "lua": "Lua",
    "m": "Objective-C",
    "markdown": "Markdown",
    "md": "Markdown",
    "mjs": "JavaScript",
    "ml": "OCaml",
    "patch": "Diff",
    "php": "PHP",
    "pl": "Perl",
    "ps1": "PowerShell",
    "py": "Python",
    "r": "R",
    "rb": "Ruby",
    "rs": "Rust",
    "sass": "Sass",
    "scala": "Scala",
    "scm": "Scheme",
    "scss": "SCSS",
    "sh": "Shell",
    "sql": "SQL",
    "svelte": "Svelte",
    "swift": "Swift",
    "tex": "TeX",
    "toml": "TOML",
    "ts": "TypeScript",
    "tsx": "TypeScript JSX",
    "txt": "Plain text",
    "vim": "Vim script",
    "vue": "Vue",
    "xml": "XML",
    "yaml": "YAML",
    "yml": "YAML",
    "zig": "Zig",
    "zsh": "Zsh",
}


def log(line: str) -> None:
    """Append a single line to the log. We log ONLY language, XP and
    timestamp — never file paths or content."""
    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with LOG_PATH.open("a", encoding="utf-8") as f:
            f.write(line.rstrip() + "\n")
    except OSError:
        pass  # Logging never blocks the hook.


def coded_at_now() -> str:
    """Return the current local time in the format the Code::Stats docs
    show (ISO 8601 with colon-separated TZ offset, e.g. 2026-06-13T01:23:45+03:00)."""
    now = datetime.now().astimezone()
    base = now.strftime("%Y-%m-%dT%H:%M:%S")
    tz = now.strftime("%z")  # +HHMM or -HHMM
    if tz and len(tz) == 5:
        tz = tz[:3] + ":" + tz[3:]
    return f"{base}{tz}"


def load_api_key() -> str | None:
    """Resolve the API key. Prefer the env var; fall back to parsing a
    shell-style `CODESTATS_API_KEY=...` line from secrets.sh next to this
    script. We do not source the shell file; we parse it, so the script
    has no side effects on the calling environment."""
    env_key = os.environ.get(API_KEY_ENV, "").strip()
    if env_key and env_key != "YOUR_API_KEY_HERE":
        return env_key
    if SECRETS_SH_FALLBACK.is_file():
        try:
            for raw in SECRETS_SH_FALLBACK.read_text(encoding="utf-8").splitlines():
                line = raw.strip()
                if line.startswith("export "):
                    line = line[len("export "):].lstrip()
                if not line.startswith("CODESTATS_API_KEY"):
                    continue
                _, _, value = line.partition("=")
                value = value.strip().strip('"').strip("'")
                if value and value != "YOUR_API_KEY_HERE":
                    return value
        except OSError:
            pass
    return None


def detect_language(file_path: str) -> str | None:
    """Map a file path to a canonical Code::Stats language name by its
    extension. Path is used only for splitext; nothing else about the path
    informs the result. Returns None for unknown extensions (event drops)."""
    if not file_path:
        return None
    _, ext = os.path.splitext(file_path)
    return EXTENSION_LANGUAGE.get(ext.lstrip(".").lower())


def compute_xp(tool_name: str, tool_input: dict) -> int:
    """1 XP per line of new content, matching the prior bash hook's policy
    so accumulated user XP doesn't visibly reset."""
    field = {
        "Edit": "new_string",
        "Write": "content",
        "NotebookEdit": "new_source",
    }.get(tool_name)
    if field is None:
        return 0
    content = tool_input.get(field, "") or ""
    if not isinstance(content, str) or not content:
        return 0
    lines = content.count("\n")
    if not content.endswith("\n"):
        lines += 1
    return max(lines, 0)


def post_pulse(api_key: str, language: str, xp: int) -> tuple[bool, int, str]:
    """POST a single pulse. Returns (ok, http_status, body_or_error_str)."""
    payload = json.dumps(
        {"coded_at": coded_at_now(), "xps": [{"language": language, "xp": xp}]}
    ).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=payload,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-API-Token": api_key,
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = resp.read(512).decode("utf-8", errors="replace")
            return (200 <= resp.status < 300, resp.status, body)
    except urllib.error.HTTPError as e:
        try:
            body = e.read(512).decode("utf-8", errors="replace")
        except Exception:
            body = ""
        return (False, e.code, body)
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        return (False, -1, str(e))


def main() -> int:
    try:
        raw = sys.stdin.read()
        event = json.loads(raw) if raw.strip() else {}
    except (ValueError, OSError):
        return 0

    tool_name = event.get("tool_name") or ""
    tool_input = event.get("tool_input") or {}
    file_path = tool_input.get("file_path") or ""

    language = detect_language(file_path)
    if language is None:
        # Unknown extension: drop silently. The pulse never leaves the box,
        # the log never records the path. New private projects need no
        # config because the only data that crosses the wire is the
        # language name from EXTENSION_LANGUAGE.
        return 0

    xp = compute_xp(tool_name, tool_input)
    if xp <= 0:
        return 0

    api_key = load_api_key()
    if not api_key:
        return 0  # Don't block the tool call just because creds are missing.

    ok, status, _body = post_pulse(api_key, language, xp)
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if ok:
        log(f"{stamp} +XP {xp} ({language})")
    else:
        log(f"{stamp} error status={status} language={language} xp={xp}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
