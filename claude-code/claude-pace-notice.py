#!/usr/bin/env python3
"""UserPromptSubmit hook: surface Claude Code weekly-limit pace in the session.

Injected as context rather than printed, so it shows up in the conversation the
same way the task-list rule does.

Deliberately quiet. It speaks on a slow interval, or sooner when the verdict
changes or the week is at risk. A nag on every prompt would be ignored within a
day, and the point is to be believed on the one Tuesday it matters.

Exits silently on any problem: a broken hook must never block a prompt.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
PACE_PY = os.path.join(HOME, ".claude", "claude-pace.py")
STATE = os.path.join(HOME, ".claude", "pace", "notice-state.json")

# Routine check-in cadence, and the shorter one used when the week is at risk or
# already running hot.
INTERVAL_NORMAL_S = 3 * 3600
INTERVAL_URGENT_S = 45 * 60
URGENT = {"ahead", "at_risk"}


def emit(text):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": text,
    }}))


def read_state():
    try:
        with open(STATE, encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return {}


def write_state(st):
    try:
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        tmp = STATE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(st, fh)
        os.replace(tmp, STATE)
    except Exception:
        pass


def main():
    # The hook is handed the prompt payload on stdin; drain it so the writer
    # never sees a broken pipe, then ignore it.
    try:
        sys.stdin.read()
    except Exception:
        pass

    if not os.path.exists(PACE_PY):
        return 0

    try:
        out = subprocess.run([sys.executable, PACE_PY, "--json"],
                             capture_output=True, text=True, timeout=10)
        c = json.loads(out.stdout)
    except Exception:
        return 0

    if not c.get("ok"):
        return 0

    verdict = c.get("verdict")
    critical = bool(c.get("critical"))
    now = time.time()

    st = read_state()
    last_ts = float(st.get("last_shown_ts") or 0)
    last_verdict = st.get("last_verdict")

    interval = INTERVAL_URGENT_S if (verdict in URGENT or critical) else INTERVAL_NORMAL_S
    due = (now - last_ts) >= interval
    # A change of verdict is news even mid-interval; the same verdict repeated is not.
    changed = verdict != last_verdict

    if not (due or changed):
        return 0

    w = c["weekly_used_pct"]
    el = c["week_elapsed_pct"]
    reset_in_h = c["reset_in_s"] / 3600.0
    today = c["today_budget_pct"]

    bits = [
        f"CLAUDE CODE WEEKLY PACE ({verdict.replace('_', ' ')}): "
        f"{w:.0f}% of the weekly limit used, {el:.0f}% of the week elapsed "
        f"({c['pace_delta_pp']:+.0f}pp).",
        f"Resets in {reset_in_h:.0f}h. Budget for the rest of today: about {today:.0f}% "
        f"more (aim to end the day near {c['today_target_total_pct']:.0f}%).",
    ]

    models = c.get("burn", {}).get("models") or {}
    if models and today > 0:
        pretty = []
        for mid, info in sorted(models.items(), key=lambda kv: kv[1]["rate"]):
            r = info["rate"]
            if r > 0:
                name = mid.replace("claude-", "").replace("-", " ").replace("[1m]", "").strip()
                pretty.append(f"~{today / r:.1f}h of {name}")
        if pretty:
            bits.append("That is roughly " + ", or ".join(pretty) + " at your measured burn rates.")

    if critical and c.get("exhaust_ts"):
        hrs = (c["exhaust_ts"] - now) / 3600.0
        left = (c["reset_ts"] - c["exhaust_ts"]) / 3600.0
        bits.append(f"WARNING: at the current rate the weekly limit is gone in about "
                    f"{hrs:.0f}h, roughly {left / 24:.1f} days before the reset. "
                    f"Move routine work to a cheaper model or slow down.")
    elif c.get("projected_end_pct") is not None and c["projected_end_pct"] < 90:
        bits.append(f"On the current trajectory the week ends at only "
                    f"{c['projected_end_pct']:.0f}%, leaving about "
                    f"{100 - c['projected_end_pct']:.0f}% of a paid-for allowance unused. "
                    f"Lean into the heavier model.")

    if c.get("five_hour_used_pct") is not None and c["five_hour_used_pct"] >= 70:
        bits.append(f"Note the 5-hour window is at {c['five_hour_used_pct']:.0f}% - "
                    f"that will bite before the weekly limit does.")

    bits.append("Mention this to Rolle only if it is useful or he asks; do not "
                "derail the current task for it.")

    emit(" ".join(bits))
    write_state({"last_shown_ts": now, "last_verdict": verdict})
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
