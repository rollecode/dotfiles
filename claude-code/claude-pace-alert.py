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

# Where to push, and to whom. This repo is public, so no chat id or private
# project path is baked in: it comes from the environment or from a local,
# gitignored config file. With neither configured the alert simply does not
# push, and the in-session notice still works.
CONFIG = os.environ.get(
    "CLAUDE_PACE_CONFIG",
    os.path.join(HOME, ".config", "claude-pace", "config.json"),
)


def _config():
    try:
        with open(CONFIG, encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return {}


_cfg = _config()
IPC_DIR = os.environ.get("CLAUDE_PACE_IPC_DIR") or _cfg.get("ipc_dir") or ""
CHAT_JID = os.environ.get("CLAUDE_PACE_CHAT_JID") or _cfg.get("chat_jid") or ""
# Optional: several chats to choose between, so the nudge lands where Rolle
# actually is instead of being broadcast to every channel at once.
CHANNELS = _cfg.get("channels") or []
MESSAGES_DB = _cfg.get("messages_db") or ""
LEDGER = os.path.join(HOME, ".claude", "usage-pace.jsonl")
# A ledger sample this fresh means a Claude Code session is live right now, and
# the in-session hook is already showing the pace there.
IN_SESSION_S = 10 * 60


def claude_code_active():
    """True when a Claude Code status line has reported within IN_SESSION_S."""
    try:
        mtime = os.path.getmtime(LEDGER)
    except Exception:
        return False
    return (time.time() - mtime) < IN_SESSION_S


def active_channel():
    """Pick the chat Rolle used most recently.

    Sending the same nudge to Telegram and Slack at once is how a useful signal
    turns into noise. The stored message history is the only live evidence of
    where he actually is, so the most recent inbound message wins.
    """
    if not CHANNELS:
        return IPC_DIR, CHAT_JID
    best = None
    if MESSAGES_DB and os.path.exists(MESSAGES_DB):
        try:
            import sqlite3
            con = sqlite3.connect(f"file:{MESSAGES_DB}?mode=ro", uri=True, timeout=3)
            for ch in CHANNELS:
                row = con.execute(
                    "SELECT MAX(timestamp) FROM messages "
                    "WHERE chat_jid = ? AND is_from_me = 0",
                    (ch.get("chat_jid", ""),)).fetchone()
                ts = row[0] if row else None
                if ts and (best is None or ts > best[0]):
                    best = (ts, ch)
            con.close()
        except Exception:
            best = None
    ch = best[1] if best else CHANNELS[0]
    return ch.get("ipc_dir", IPC_DIR), ch.get("chat_jid", CHAT_JID)

# Never re-alert the same state inside this window, even on a fresh escalation,
# so a percentage flapping on a boundary cannot machine-gun the chat.
IPC_DIR_USED = []
MIN_GAP_S = 20 * 60
# Say something at least once a day even if nothing changed.
DAILY_FLOOR_S = 20 * 3600
QUIET_START, QUIET_END = 23, 8


def _plural(n, word):
    return f"{n} {word}" if n == 1 else f"{n} {word}s"


def fmt_dur(seconds):
    """Durations in full words: "6 days 8 hours", not "6d 8h"."""
    seconds = max(0, int(seconds))
    d, rem = divmod(seconds, 86400)
    h, rem = divmod(rem, 3600)
    m = rem // 60
    if d:
        return _plural(d, "day") + (" " + _plural(h, "hour") if h else "")
    if h:
        return _plural(h, "hour") + (" " + _plural(m, "minute") if m else "")
    return _plural(m, "minute")


def fmt_hours(hours):
    """Working hours rounded to 5 minutes and written out, never "1.0h"."""
    total_m = int(round((hours * 60) / 5.0) * 5)
    if total_m <= 0:
        return "under 5 minutes"
    h, m = divmod(total_m, 60)
    if h and m:
        return _plural(h, "hour") + " " + _plural(m, "minute")
    if h:
        return _plural(h, "hour")
    return _plural(m, "minute")


def pretty_model(mid):
    """claude-opus-5[1m] -> Opus 5. The blunt version produced "opus 5"."""
    m = str(mid).replace("[1m]", "").split("/")[-1]
    parts = [p for p in m.split("-") if p and p != "claude"]
    if parts and len(parts[-1]) == 8 and parts[-1].isdigit():
        parts = parts[:-1]
    if not parts:
        return m
    return (parts[0].capitalize() + " " + ".".join(parts[1:])).strip()


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
    ipc_dir, chat_jid = active_channel()
    if not ipc_dir or not chat_jid or not os.path.isdir(ipc_dir):
        return False
    IPC_DIR_USED.append(ipc_dir)
    payload = {"type": "message", "chatJid": chat_jid, "text": text}
    name = f"pace-{int(time.time())}-{uuid.uuid4().hex[:6]}.json"
    tmp = os.path.join(ipc_dir, "." + name)
    final = os.path.join(ipc_dir, name)
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
    # Heading for a big underspend is the other way to waste the plan, and it was
    # missing from the key entirely: a week tracking to finish at 78% sat on
    # verdict "on_pace" forever and never said a word. Bucketed so it announces
    # once per band rather than on every drifting percent.
    p_end = c.get("projected_end_pct")
    if p_end is None:
        parts.append("end-unknown")
    elif p_end < 60:
        parts.append("end-way-under")
    elif p_end < 80:
        parts.append("end-under")
    elif p_end < 95:
        parts.append("end-slightly-under")
    else:
        parts.append("end-full")
    return "|".join(str(p) for p in parts)


def build_message(c):
    verdict = c.get("verdict")
    w = c["weekly_used_pct"]
    el = c["week_elapsed_pct"]
    today = c["today_budget_pct"]
    p_end = c.get("projected_end_pct")
    wasting = (100 - p_end) if p_end is not None else 0
    head = {
        "at_risk": "*Claude Code weekly usage budget* - at risk, today's rate runs it dry early",
        "ahead": "*Claude Code weekly usage budget* - ahead of pace, ease off",
        "behind": "*Claude Code weekly usage budget* - behind pace, room to spend",
        "on_pace": "*Claude Code weekly usage budget* - on pace",
    }.get(verdict, "*Claude Code weekly usage budget*")
    # Tracking to leave a fifth of the plan unused is the headline, whatever the
    # cumulative verdict says.
    if verdict != "at_risk" and wasting >= 20:
        head = (f"*Claude Code weekly usage budget* - on track to waste "
                f"{wasting:.0f}% of the plan")

    d = c["pace_delta_pp"]
    L = [head, ""]
    # "4% used, 9% gone" side by side read as a contradiction, so each figure
    # names what it measures and the comparison is words, not "pp".
    L.append(f"Limit spent: *{w:.0f}%* of this week's allowance")
    L.append(f"Time gone: *{el:.0f}%* of the week (resets in {fmt_dur(c['reset_in_s'])})")
    if d < -1:
        L.append(f"You are spending slower than the clock, by {abs(d):.0f} points.")
    elif d > 1:
        L.append(f"You are spending faster than the clock, by {d:.0f} points.")
    else:
        L.append("Your spending is tracking the clock almost exactly.")
    L.append("")
    L.append(f"Today you can spend about *{today:.0f}%* more, "
             f"ending the day near {c['today_target_total_pct']:.0f}%.")

    models = (c.get("burn") or {}).get("models") or {}
    if models and today > 0:
        bits = [f"*{fmt_hours(today / i['rate'])}* of {pretty_model(m)}"
                for m, i in sorted(models.items(), key=lambda kv: kv[1]["rate"])
                if i["rate"] > 0]
        if bits:
            L.append("")
            L.append("That is roughly " + ", or ".join(bits) + ".")

    if c.get("critical") and c.get("exhaust_ts"):
        early = c.get("exhaust_early_by_s") or 0
        L.append("")
        L.append(f"At this rate it runs out *{fmt_dur(early)} before the reset*, "
                 f"which is days without Claude Code. Move routine work to a "
                 f"cheaper model.")
    elif c.get("on_target") and c.get("exhaust_ts"):
        early = c.get("exhaust_early_by_s") or 0
        L.append("")
        L.append(f"At this rate it runs out about {fmt_dur(early)} before the reset. "
                 f"That is the target, keep going.")
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

    # Already visible where he is working: the in-session hook shows the same
    # thing. Pushing to chat as well is what made this feel relentless.
    if claude_code_active():
        return 0

    key = alert_key(c)
    st = read_state()
    # Same situation as last time: normally silent, but not for a whole day.
    # Going quiet for 24h while the week drifts is how this ends up ignored.
    if st.get("key") == key and (now - float(st.get("ts") or 0)) < DAILY_FLOOR_S:
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
