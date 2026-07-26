#!/usr/bin/env python3
"""Push a Claude Code pace alert the moment the situation changes.

The scheduled nanoclaw nudge is a slow safety net; polling on a cron cannot tell
you "you are burning too fast" while it is still actionable. This runs from the
statusline recorder, so it sees the weekly percentage tick the second Claude Code
reports it, and pushes straight into nanoclaw's IPC message queue - picked up
within about a second, with no container spawn and no model call.

Only state CHANGES are pushed, never the steady state, so it stays silent for
days at a time and is therefore still worth reading when it fires.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
import uuid

HOME = os.path.expanduser("~")
PACE_PY = os.path.join(HOME, ".claude", "claude-pace.py")
STATE = os.path.join(HOME, ".claude", "pace", "alert-state.json")

IPC_DIR = os.environ.get(
    "CLAUDE_PACE_IPC_DIR",
    os.path.join(HOME, "Projects", "nanoclaw", "data", "ipc", "telegram_main", "messages"),
)
CHAT_JID = os.environ.get("CLAUDE_PACE_CHAT_JID", "tg:25957634")

# Never re-alert the same state inside this window, even on a fresh escalation,
# so a percentage flapping on a boundary cannot machine-gun the chat.
MIN_GAP_S = 20 * 60
QUIET_START, QUIET_END = 23, 8


def fmt_dur(seconds):
    seconds = max(0, int(seconds))
    d, rem = divmod(seconds, 86400)
    h, rem = divmod(rem, 3600)
    m = rem // 60
    if d:
        return f"{d}d {h}h"
    if h:
        return f"{h}h {m}m"
    return f"{m}m"


def pretty_model(mid):
    return (str(mid).replace("[1m]", "").replace("claude-", "")
            .replace("-", " ").strip())


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


def push(text):
    """Hand the message to nanoclaw's IPC watcher via an atomic rename."""
    if not os.path.isdir(IPC_DIR):
        return False
    payload = {"type": "message", "chatJid": CHAT_JID, "text": text}
    name = f"pace-{int(time.time())}-{uuid.uuid4().hex[:6]}.json"
    tmp = os.path.join(IPC_DIR, "." + name)
    final = os.path.join(IPC_DIR, name)
    try:
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(payload, fh)
        os.replace(tmp, final)
        return True
    except Exception:
        try:
            os.unlink(tmp)
        except Exception:
            pass
        return False


def alert_key(c):
    """What counts as 'the situation'. A new key means something worth saying."""
    parts = [c.get("verdict"), "crit" if c.get("critical") else "ok"]
    h5 = c.get("five_hour_used_pct") or 0
    # Only the 5-hour cliff matters, not every percent of it.
    parts.append("h5-90" if h5 >= 90 else ("h5-75" if h5 >= 75 else "h5-low"))
    return "|".join(str(p) for p in parts)


def build_message(c):
    verdict = c.get("verdict")
    w = c["weekly_used_pct"]
    el = c["week_elapsed_pct"]
    today = c["today_budget_pct"]
    head = {
        "at_risk": "*Claude Code weekly usage budget* - at risk, today's rate runs it dry early",
        "ahead": "*Claude Code weekly usage budget* - ahead of pace, ease off",
        "behind": "*Claude Code weekly usage budget* - behind pace, room to spend",
        "on_pace": "*Claude Code weekly usage budget* - back on pace",
    }.get(verdict, "*Claude Code weekly usage budget*")

    L = [head, ""]
    L.append(f"Used *{w:.0f}%* of the weekly limit, *{el:.0f}%* of the week gone "
             f"({c['pace_delta_pp']:+.0f}pp). Resets in {fmt_dur(c['reset_in_s'])}.")
    L.append("")
    L.append(f"Budget for the rest of today: *{today:.0f}%* more, "
             f"ending near {c['today_target_total_pct']:.0f}%.")

    models = (c.get("burn") or {}).get("models") or {}
    if models and today > 0:
        bits = [f"*{today / i['rate']:.1f}h* of {pretty_model(m)}"
                for m, i in sorted(models.items(), key=lambda kv: kv[1]["rate"])
                if i["rate"] > 0]
        if bits:
            L.append("")
            L.append("That is roughly " + ", or ".join(bits) + ".")

    if c.get("critical") and c.get("exhaust_ts"):
        gone_in = c["exhaust_ts"] - time.time()
        early = c["reset_ts"] - c["exhaust_ts"]
        L.append("")
        L.append(f"At this rate the weekly limit is gone in *{fmt_dur(gone_in)}*, "
                 f"about {fmt_dur(early)} before the reset. Move routine work to a "
                 f"cheaper model.")
    elif c.get("projected_end_pct") is not None and c["projected_end_pct"] < 90:
        L.append("")
        L.append(f"On this trajectory the week ends at only "
                 f"*{c['projected_end_pct']:.0f}%*, wasting about "
                 f"{100 - c['projected_end_pct']:.0f}% you have already paid for.")

    h5 = c.get("five_hour_used_pct")
    if h5 is not None and h5 >= 75:
        L.append("")
        L.append(f"5-hour window is at *{h5:.0f}%* "
                 f"({fmt_dur(c['five_hour_reset_in_s'] or 0)} to reset) - that bites "
                 f"before the weekly limit does.")

    return "\n".join(L)


def main():
    if not os.path.exists(PACE_PY):
        return 0
    try:
        out = subprocess.run([sys.executable, PACE_PY, "--json"],
                             capture_output=True, text=True, timeout=15)
        c = json.loads(out.stdout)
    except Exception:
        return 0
    if not c.get("ok"):
        return 0

    now = time.time()
    if time.localtime(now).tm_hour >= QUIET_START or time.localtime(now).tm_hour < QUIET_END:
        return 0

    key = alert_key(c)
    st = read_state()
    if st.get("key") == key:
        return 0
    if (now - float(st.get("ts") or 0)) < MIN_GAP_S:
        return 0

    # A first run has nothing to compare against; record the baseline rather than
    # opening with an alert about a state that may have been true for days.
    if not st.get("key"):
        write_state({"key": key, "ts": now})
        return 0

    if push(build_message(c)):
        write_state({"key": key, "ts": now})
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
