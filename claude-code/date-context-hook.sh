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

HOOK_INPUT=$(cat 2>/dev/null || true)

python3 - "$CONTEXT" "$HOOK_INPUT" <<'PY' 2>/dev/null
import json, os, re, sys
from datetime import datetime

context = sys.argv[1]


# Closing hour: from an hour before the workday end, tell the model to steer Rolle out.
# Hours and days off come from the same Brain dump files NanoClaw reads.
def worked_in_hours(transcript, now, start, end):
    """A session with activity inside today's hours is the workday running over; one without is free time."""
    day = now.date()
    with open(transcript) as f:
        for line in f:
            m = re.search(r'"timestamp":"([^"]+)"', line)
            if not m:
                continue
            ts = datetime.fromisoformat(m.group(1).replace("Z", "+00:00")).astimezone()
            if ts.date() == day and start <= ts.strftime("%H:%M") < end:
                return True
    return False


def closing_note(now, transcript):
    bd = os.environ.get("BRAIN_DUMP", os.path.expanduser("~/Documents/Brain dump"))
    today = now.date().isoformat()

    def read(name):
        try:
            with open(os.path.join(bd, name)) as f:
                return [l.strip() for l in f if l.strip() and not l.startswith("#")]
        except OSError:
            return []

    def covers(spec):
        a, _, b = spec.partition("..")
        return a <= today <= (b or a)

    if now.weekday() >= 5 or any(l == "always" or covers(l.split()[0]) for l in read("day-off.txt")):
        return ""
    if any(today in l for l in read("Finnish public holidays.md")):
        return ""

    start, end = "10:00", "18:00"
    for l in read("work-hours.txt"):
        p = l.split()
        if len(p) == 2 and re.fullmatch(r"\d\d:\d\d-\d\d:\d\d", p[1]) and covers(p[0]):
            start, end = p[1].split("-")

    h, m = map(int, end.split(":"))
    past = now.hour * 60 + now.minute - (h * 60 + m)
    if past < -60 or past >= 300:
        return ""
    if past < 0:
        return (f" Closing hour: Rolle's workday ends at {end}, {-past} min left. Do not start anything new"
                " with him on work; steer toward finishing or parking what is open.")
    if not transcript or not worked_in_hours(transcript, now, start, end):
        return ""
    return (f" Rolle is {past} min past his workday end {end}, still in a session he worked in today. Unless he has said he is"
            " stretching today, open your reply with one plain line telling him to stop and offer to park"
            " the work with a note of where it stopped. Do not refuse the request. Once every 30 min or so"
            " is enough, not every reply.")


try:
    hook = json.loads(sys.argv[2] or "{}")
    context += closing_note(datetime.now(), hook.get("transcript_path"))
except Exception:
    pass

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": context,
    }
}))
PY
exit 0
