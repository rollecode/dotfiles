#!/usr/bin/env bash
# date-context-hook.sh - UserPromptSubmit hook: stamp the real date onto every prompt.
#
# A Claude Code session that spans midnight keeps whatever date it inferred at
# session start in its own working context. Nothing forces it to re-check, so a
# session opened Thursday evening still believes it is Thursday on Friday
# morning - it ran /plan_today at 17:46 thinking the workday was ending, then at
# 10:27 the NEXT day was still reasoning from Thursday's date until asked to run
# `date` directly.
#
# Fails silently: a broken hook must never block a prompt.
set -uo pipefail

# English weekday regardless of host locale, matching the convention used
# elsewhere (e.g. nanoclaw's life-changelog-check.sh) so downstream text parsing
# and reasoning about "Friday" is never locale-dependent.
NOW=$(LC_ALL=C date '+%A %d.%m.%Y %H:%M %Z' 2>/dev/null) || exit 0
ISO=$(date '+%Y-%m-%d' 2>/dev/null) || exit 0

CONTEXT="Current real date and time (authoritative, overrides anything assumed earlier in this session): ${NOW} (${ISO})."

python3 - "$CONTEXT" <<'PY' 2>/dev/null
import json, sys
context = sys.argv[1]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": context,
    }
}))
PY
exit 0
