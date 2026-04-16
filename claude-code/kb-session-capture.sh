#!/usr/bin/env bash
# SessionEnd hook: capture Claude Code session into Knowledge base raw/claude-sessions/
# Reads JSON on stdin (session_id, transcript_path, cwd, hook_event_name).

set -euo pipefail

KB_RAW="/Users/rolle/Documents/Knowledge base/sources/claude-sessions"
LOG="/Users/rolle/.claude/kb-session-capture.log"

mkdir -p "$KB_RAW"

INPUT="$(cat)"

/usr/bin/python3 - <<'PY' "$INPUT" "$KB_RAW" "$LOG"
import json, sys, os, datetime, re

payload, kb_raw, log_path = sys.argv[1], sys.argv[2], sys.argv[3]

def log(msg):
    try:
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"{datetime.datetime.now().isoformat(timespec='seconds')} {msg}\n")
    except Exception:
        pass

try:
    data = json.loads(payload)
except Exception as e:
    log(f"bad json input: {e}")
    sys.exit(0)

transcript = data.get("transcript_path") or ""
session_id = data.get("session_id") or ""
cwd = data.get("cwd") or ""

if not transcript or not os.path.isfile(transcript):
    log(f"no transcript file: {transcript}")
    sys.exit(0)

# Skip sessions about the Knowledge base itself to avoid self-referential noise.
if "Knowledge base" in cwd:
    log(f"skip KB self-session: {cwd}")
    sys.exit(0)

turns = []
try:
    with open(transcript, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                ev = json.loads(line)
            except Exception:
                continue
            t = ev.get("type")
            if t == "user":
                msg = ev.get("message", {}) or {}
                content = msg.get("content")
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    parts = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
                    text = "\n".join(p for p in parts if p)
                else:
                    text = ""
                text = text.strip()
                if not text:
                    continue
                if text.startswith("<command-") or "<system-reminder>" in text or "<local-command-stdout>" in text:
                    continue
                turns.append(("user", text))
            elif t == "assistant":
                msg = ev.get("message", {}) or {}
                content = msg.get("content", [])
                if isinstance(content, list):
                    parts = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
                    text = "\n".join(p for p in parts if p)
                else:
                    text = str(content or "")
                text = text.strip()
                if text:
                    turns.append(("assistant", text))
except Exception as e:
    log(f"parse error: {e}")
    sys.exit(0)

if not turns:
    log("no turns captured")
    sys.exit(0)

def slug(s):
    s = re.sub(r"[^A-Za-z0-9]+", "-", s or "unknown").strip("-").lower()
    return s or "unknown"

project_slug = slug(os.path.basename(cwd or "unknown"))
ts = datetime.datetime.now().strftime("%Y-%m-%d-%H%M")
short_sid = (session_id or "")[:8] or "nosid"
out = os.path.join(kb_raw, f"{ts}-{project_slug}-{short_sid}.md")

iso_now = datetime.datetime.now().isoformat(timespec="seconds")
lines = [
    "---",
    f'title: "Claude Code session {short_sid} in {project_slug}"',
    f'session_id: "{session_id}"',
    f'cwd: "{cwd}"',
    f'ingested_at: {iso_now}',
    'source: claude-code',
    'tags: [claude-session]',
    "---",
    "",
    f"# Claude Code session {short_sid}",
    "",
    f"**Project:** `{cwd}`",
    "",
    f"**Captured:** {iso_now}",
    "",
]
for role, text in turns:
    # Filter out Dayflow timeline data - it's noisy screen observations, not knowledge
    if any(kw in text for kw in ["dayflow_get_timeline", "dayflow_get_observations", "dayflow_search_timeline", "dayflow_get_daily_stats", "dayflow_get_recent_activity", '"appSites"', '"distractions"', "start_ts", "end_ts"]):
        continue
    lines.append(f"## {role}")
    lines.append("")
    lines.append(text)
    lines.append("")

os.makedirs(kb_raw, exist_ok=True)
with open(out, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

log(f"wrote {out} ({len(turns)} turns)")
PY
