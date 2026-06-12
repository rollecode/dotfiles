#!/usr/bin/env python3
"""
Code::Stats Claude Code hook — structural, no hacks.

Behaviour:
  - Reads the Edit/Write/NotebookEdit tool input JSON from stdin.
  - Computes the language ONLY from the file extension via a fixed
    extension → official Code::Stats language name table.
  - Computes XP as the line count of the new content (Edit's new_string,
    Write's content, NotebookEdit's new_source) — matching the existing
    hook's pulse policy of "1 XP per line".
  - POSTs ONLY {coded_at, xps:[{language, xp}]} to codestats.net.
  - Drops the event silently if the extension isn't in the table. This
    guarantees no path, no project name, no content can ever leak —
    by construction, not by allow/deny-list maintenance.

The extension table is closed-set: new private projects don't need any
config to be safe, because the only thing that ever crosses the network
is the language tag itself ("Python", "TypeScript", …), the XP count,
and the timestamp.

Failure modes are silent (exit 0) so a flaky network never blocks an
Edit or Write tool call.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

API_URL = "https://codestats.net/api/my/pulses"
LOG_PATH = Path.home() / ".claude" / "codestats-hook.log"
API_KEY_ENV = "CODESTATS_API_KEY"
API_KEY_FILE_FALLBACK = Path.home() / "Projects" / "dotfiles" / "claude-code" / "secrets.sh"


# Extension → official Code::Stats language name. Closed set.
# Sourced from code-stats-vscode and code-stats-python's published mappings,
# trimmed to extensions a Claude Code session is likely to touch. Add new
# entries here when you start using a new language; new PROJECTS need no
# config because they don't affect the pulse payload.
EXTENSION_LANGUAGE = {
    "bash": "Bash",
    "c": "C",
    "cc": "C++",
    "cjs": "JavaScript",
    "cpp": "C++",
    "cs": "C#",
    "css": "CSS",
    "csv": "CSV",
    "cxx": "C++",
    "dart": "Dart",
    "diff": "Diff",
    "dockerfile": "Dockerfile",
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
    "ini": "Plain text",
    "java": "Java",
    "jl": "Julia",
    "js": "JavaScript",
    "json": "JSON",
    "jsx": "JavaScript JSX",
    "kt": "Kotlin",
    "less": "Less",
    "lua": "Lua",
    "m": "Objective-C",
    "md": "Markdown",
    "markdown": "Markdown",
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
    """Append a single line to the log. Logs ONLY language and XP — never
    file paths or content."""
    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with LOG_PATH.open("a", encoding="utf-8") as f:
            f.write(line.rstrip() + "\n")
    except OSError:
        # Logging never blocks the hook.
        pass


def load_api_key() -> str | None:
    """Resolve the Code::Stats API key. Prefers an env var the user can set
    explicitly, falls back to the legacy secrets.sh shell file."""
    env_key = os.environ.get(API_KEY_ENV, "").strip()
    if env_key and env_key != "YOUR_API_KEY_HERE":
        return env_key
    if API_KEY_FILE_FALLBACK.is_file():
        # The file is shell: CODESTATS_API_KEY="...". Parse with a tolerant
        # split rather than sourcing it.
        try:
            for raw in API_KEY_FILE_FALLBACK.read_text(encoding="utf-8").splitlines():
                line = raw.strip()
                # Tolerate both bare assignments and `export FOO=...`.
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
    """Map a file path to an official Code::Stats language name strictly via
    its extension. Returns None if the extension is not in the closed set,
    which causes the caller to drop the event entirely. Path is never used
    for anything other than extracting the lowercase extension."""
    if not file_path:
        return None
    # `os.path.splitext` returns ('LICENSE', '') when there's no dot; that
    # falls through to None, which is exactly what we want.
    _, ext = os.path.splitext(file_path)
    ext = ext.lstrip(".").lower()
    return EXTENSION_LANGUAGE.get(ext)


def compute_xp(tool_name: str, tool_input: dict) -> int:
    """1 XP per line of the new content the tool is writing. Matches the
    existing hook's policy so accumulated XP doesn't reset visibly."""
    if tool_name == "Edit":
        content = tool_input.get("new_string", "")
    elif tool_name == "Write":
        content = tool_input.get("content", "")
    elif tool_name == "NotebookEdit":
        content = tool_input.get("new_source", "")
    else:
        return 0
    if not isinstance(content, str) or not content:
        return 0
    # Match the upstream bash logic: `wc -l` counts newlines; one extra if
    # the buffer doesn't terminate with a newline.
    line_count = content.count("\n")
    if not content.endswith("\n"):
        line_count += 1
    return max(line_count, 0)


def post_pulse(api_key: str, language: str, xp: int) -> tuple[bool, int]:
    """POST a single pulse. Returns (ok, http_status_or_-1_on_network_error)."""
    payload = json.dumps(
        {
            "coded_at": datetime.now(timezone.utc)
            .astimezone()
            .strftime("%Y-%m-%dT%H:%M:%S%z")[:-2]
            + ":"
            + datetime.now(timezone.utc).astimezone().strftime("%z")[-2:],
            "xps": [{"language": language, "xp": xp}],
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=payload,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "X-API-Token": api_key,
            "User-Agent": "claude-code-codestats/1.0",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return (200 <= resp.status < 300, resp.status)
    except urllib.error.HTTPError as e:
        return (False, e.code)
    except (urllib.error.URLError, TimeoutError, OSError):
        return (False, -1)


def main() -> int:
    # Read stdin. Failure to parse = drop silently.
    try:
        raw = sys.stdin.read()
        event = json.loads(raw) if raw.strip() else {}
    except (ValueError, OSError):
        return 0
    tool_name = event.get("tool_name") or ""
    tool_input = event.get("tool_input") or {}
    file_path = tool_input.get("file_path") or ""

    # Language detection is the ONLY safety boundary. No path, no content,
    # no project name leaves this script unless we've identified a known
    # extension. A closed allow-list of *extensions* (not projects) means
    # new private projects need no config.
    language = detect_language(file_path)
    if language is None:
        return 0
    xp = compute_xp(tool_name, tool_input)
    if xp <= 0:
        return 0

    api_key = load_api_key()
    if not api_key:
        # Missing key = drop silently so the hook can never block a Claude
        # operation just because a credentials file went missing.
        return 0

    ok, status = post_pulse(api_key, language, xp)
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if ok:
        log(f"{stamp} +XP {xp} ({language})")
    else:
        # Never log the file path on failure; just the http status.
        log(f"{stamp} error: status={status} language={language} xp={xp}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
