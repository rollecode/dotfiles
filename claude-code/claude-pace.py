#!/usr/bin/env python3
"""claude-pace.py - are you behind or ahead of your Claude Code weekly limit?

The goal is not to save quota, it is to spend as close to 100% of the weekly
allowance as possible and have it run out just before the reset, never on
Thursday. So this reports pace against the clock, not just raw usage.

Data comes from the pace ledger written by usage-pace-record.sh, which captures
`.rate_limits` out of the statusline payload (the only place Claude Code exposes
live 5-hour and 7-day utilisation).

Nothing here is hardcoded to a weekday: the week window is derived from the
plan's own `resets_at`, so it stays correct if the anchor ever moves.

Usage:
  claude-pace.py              human-readable report
  claude-pace.py --oneline    single line, for a status bar or a chat message
  claude-pace.py --json       machine-readable
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timedelta

HOME = os.path.expanduser("~")
# Overridable so the pace maths can be exercised against synthetic weeks
# (Thursday burnout, reset boundary) without touching the real ledger.
LATEST = os.environ.get("CLAUDE_PACE_LATEST",
                        os.path.join(HOME, ".claude", "usage-pace-latest.json"))
LEDGER = os.environ.get("CLAUDE_PACE_LEDGER",
                        os.path.join(HOME, ".claude", "usage-pace.jsonl"))
STATS = os.environ.get("CLAUDE_PACE_STATS",
                       os.path.join(HOME, ".claude", "stats-cache.json"))

WEEK_S = 7 * 86400
# Gap above which two samples are treated as idle time rather than work, so a
# burn rate reflects hours actually spent working instead of hours elapsed.
ACTIVE_GAP_S = 1800
# Minimum accumulated active time before a rate is trustworthy enough to quote.
MIN_DT_OVERALL_S = 1800
MIN_DT_MODEL_S = 3600
# The usage day rolls at the same hour the week resets, which also keeps
# after-midnight work attributed to the evening it belongs to.
DAY_ROLL_HOUR = 4

FINNISH_DAYS = [
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday",
]


def _read_json(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return None


def load_ledger():
    rows = []
    try:
        with open(LEDGER, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(json.loads(line))
                except Exception:
                    continue
    except Exception:
        return []
    rows.sort(key=lambda r: r.get("ts", 0))
    return rows


def pretty_model(mid):
    """Turn a model id into the name shown in the UI."""
    if not mid or mid == "?":
        return "unknown model"
    m = str(mid)
    if m.endswith("[1m]"):
        m = m[: -len("[1m]")]
    m = m.split("/")[-1]
    parts = m.split("-")
    if parts and parts[0] == "claude":
        parts = parts[1:]
    # Drop a trailing release date (claude-opus-4-5-20251101).
    if parts and len(parts[-1]) == 8 and parts[-1].isdigit():
        parts = parts[:-1]
    if not parts:
        return m
    family = parts[0].capitalize()
    ver = ".".join(parts[1:]) if len(parts) > 1 else ""
    return f"{family} {ver}".strip()


def hour_weights():
    """Relative likelihood of working in each hour, from real session history.

    Spreading the remaining budget evenly across wall-clock hours would reserve
    quota for hours spent asleep. Weighting by observed activity puts the budget
    where the work actually happens.
    """
    stats = _read_json(STATS) or {}
    counts = stats.get("hourCounts") or {}
    weights = {}
    for h in range(24):
        try:
            weights[h] = float(counts.get(str(h), 0) or 0)
        except Exception:
            weights[h] = 0.0
    if sum(weights.values()) <= 0:
        weights = {h: 1.0 for h in range(24)}
    return weights


def weighted_span(start_ts, end_ts, weights):
    """Sum activity weight between two instants, pro-rating partial hours."""
    if end_ts <= start_ts:
        return 0.0
    total = 0.0
    cur = start_ts
    while cur < end_ts:
        dt = datetime.fromtimestamp(cur)
        hour_end = (dt.replace(minute=0, second=0, microsecond=0)
                    + timedelta(hours=1)).timestamp()
        seg_end = min(hour_end, end_ts)
        frac = (seg_end - cur) / 3600.0
        total += weights.get(dt.hour, 0.0) * frac
        cur = seg_end
    return total


def next_day_roll(now_ts):
    """The next DAY_ROLL_HOUR boundary, i.e. when 'today' stops counting."""
    dt = datetime.fromtimestamp(now_ts)
    roll = dt.replace(hour=DAY_ROLL_HOUR, minute=0, second=0, microsecond=0)
    if roll.timestamp() <= now_ts:
        roll += timedelta(days=1)
    return roll.timestamp()


def burn_rates(rows, week_start, now):
    """Observed weekly-% burn per hour of active work, overall and per model.

    Only forward-moving consecutive pairs inside the current week count. A drop
    means the window reset, and a long gap means idle, so both are skipped.
    """
    overall_dw = overall_dt = 0.0
    per_model = {}
    recent_dw = recent_dt = 0.0
    recent_cutoff = now - 6 * 3600

    prev = None
    for r in rows:
        ts = r.get("ts")
        w = r.get("w")
        if ts is None or w is None or ts < week_start:
            prev = None if ts is None or ts < week_start else r
            continue
        if prev is not None:
            dt = ts - prev.get("ts", ts)
            dw = w - prev.get("w", w)
            if 0 < dt <= ACTIVE_GAP_S and dw >= 0:
                overall_dw += dw
                overall_dt += dt
                if ts >= recent_cutoff:
                    recent_dw += dw
                    recent_dt += dt
                if r.get("model") == prev.get("model"):
                    key = r.get("model") or "?"
                    acc = per_model.setdefault(key, [0.0, 0.0])
                    acc[0] += dw
                    acc[1] += dt
        prev = r

    def rate(dw, dt, min_dt):
        if dt < min_dt:
            return None
        return dw / (dt / 3600.0)

    models = {}
    for k, (dw, dt) in per_model.items():
        r = rate(dw, dt, MIN_DT_MODEL_S)
        if r is not None:
            models[k] = {"rate": r, "active_hours": dt / 3600.0}

    return {
        "overall": rate(overall_dw, overall_dt, MIN_DT_OVERALL_S),
        "overall_active_hours": overall_dt / 3600.0,
        "recent": rate(recent_dw, recent_dt, MIN_DT_OVERALL_S),
        "recent_active_hours": recent_dt / 3600.0,
        "models": models,
    }


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


def fmt_when(ts):
    dt = datetime.fromtimestamp(ts)
    return f"{FINNISH_DAYS[dt.weekday()]} {dt.strftime('%-d.%-m.')} at {dt.strftime('%H:%M')}"


def compute():
    latest = _read_json(LATEST)
    rows = load_ledger()
    if not latest and rows:
        latest = rows[-1]
    if not latest:
        return {"ok": False, "error": "no pace data yet - open a Claude Code session so the statusline can record a sample"}

    now = time.time()
    w = latest.get("w")
    wr = latest.get("wr")
    h5 = latest.get("h5")
    hr = latest.get("hr")
    if w is None or not wr:
        return {"ok": False, "error": "pace data has no weekly limit info"}

    # A reset that has already passed means the sample predates the new window.
    stale_reset = wr <= now
    week_start = wr - WEEK_S
    elapsed = max(0.0, min(1.0, (now - week_start) / WEEK_S)) * 100.0
    delta = w - elapsed  # >0 spending faster than the clock, <0 headroom

    weights = hour_weights()
    day_end = min(next_day_roll(now), wr)
    w_today = weighted_span(now, day_end, weights)
    w_week = weighted_span(now, wr, weights)
    remaining = max(0.0, 100.0 - w)
    today_budget = remaining * (w_today / w_week) if w_week > 0 else remaining
    # Cumulative allowance for today, so the number reads the same way as the
    # utilisation percentage it will be compared against.
    today_target_total = w + today_budget

    br = burn_rates(rows, week_start, now)
    rate = br["recent"] if br["recent"] is not None else br["overall"]

    # Projecting a burn rate forward as if the next 24 hours were all spent
    # working would predict running dry almost immediately and cry wolf every
    # day. The rate is per hour of ACTIVE work, so convert it to calendar time
    # using how many active hours per day the ledger has actually seen.
    days_elapsed = max((now - week_start) / 86400.0, 0.25)
    active_h_per_day = br["overall_active_hours"] / days_elapsed
    active_h_per_day = min(max(active_h_per_day, 0.5), 16.0)

    exhaust_ts = None
    projected_end_pct = None
    if rate and rate > 0 and br["overall_active_hours"] >= 0.5:
        active_hours_needed = remaining / rate
        exhaust_ts = now + (active_hours_needed / active_h_per_day) * 86400.0
        # Where the week actually lands if nothing changes. Underspending is the
        # failure this whole thing exists to catch, so it needs a number too, not
        # just an exhaustion date sitting past the reset.
        days_left = max(0.0, (wr - now) / 86400.0)
        projected_end_pct = w + rate * active_h_per_day * days_left

    ideal_rate = remaining / (w_week / sum(weights.values()) * 24) if w_week > 0 else None

    # Judge on both the ratio and the absolute gap. Early in the week a few
    # percentage points is the whole story (2% used against 7% elapsed is barely
    # -5pp but only 29% of the expected pace), while late in the week the
    # absolute gap is what decides whether the allowance survives to the reset.
    ratio = (w / elapsed) if elapsed >= 2 else None
    if (ratio is not None and ratio >= 1.25 and delta >= 2) or delta >= 8:
        verdict = "ahead"
    elif (ratio is not None and ratio <= 0.75 and delta <= -2) or delta <= -8:
        verdict = "behind"
    else:
        verdict = "on_pace"

    # Running out before the reset is the failure mode worth shouting about.
    critical = bool(exhaust_ts and exhaust_ts < wr - 12 * 3600)

    # Cumulative position and current rate can disagree: sitting comfortably
    # behind for the week while burning fast enough today to still run dry on
    # Thursday. The rate wins, otherwise the report would cheerfully say "use it
    # freely" directly above its own exhaustion warning.
    if critical and verdict != "ahead":
        verdict = "at_risk"

    return {
        "ok": True,
        "now": now,
        "weekly_used_pct": w,
        "week_elapsed_pct": elapsed,
        "pace_delta_pp": delta,
        "verdict": verdict,
        "pace_ratio": ratio,
        "current_model": latest.get("model"),
        "critical": critical,
        "stale_reset": stale_reset,
        "reset_ts": wr,
        "reset_in_s": max(0, wr - now),
        "remaining_pct": remaining,
        "today_budget_pct": today_budget,
        "today_target_total_pct": today_target_total,
        "day_end_ts": day_end,
        "five_hour_used_pct": h5,
        "five_hour_reset_ts": hr,
        "five_hour_reset_in_s": max(0, (hr - now)) if hr else None,
        "burn": br,
        "burn_rate_used": rate,
        "active_hours_per_day": active_h_per_day,
        "exhaust_ts": exhaust_ts,
        "projected_end_pct": projected_end_pct,
        "ideal_daily_rate": ideal_rate,
        "samples": len(rows),
        "sample_age_s": max(0, now - latest.get("ts", now)),
    }


def model_hours(c):
    """Hours of headroom today per model, at each model's observed burn rate."""
    out = []
    budget = c["today_budget_pct"]
    for mid, info in sorted(c["burn"]["models"].items(),
                            key=lambda kv: kv[1]["rate"]):
        r = info["rate"]
        if r <= 0:
            out.append((pretty_model(mid), None, r))
        else:
            out.append((pretty_model(mid), budget / r, r))
    return out


def render(c, oneline=False):
    if not c.get("ok"):
        return f"Claude Code pace: {c.get('error')}"

    w = c["weekly_used_pct"]
    el = c["week_elapsed_pct"]
    d = c["pace_delta_pp"]
    verdict = c["verdict"]

    if oneline:
        tag = {"behind": "behind (headroom)",
               "ahead": "ahead (ease off)",
               "at_risk": "burning too fast today",
               "on_pace": "on pace"}[verdict]
        s = (f"Claude Code weekly: {w:.0f}% used, {el:.0f}% of week gone "
             f"({d:+.0f}pp, {tag}). Today's budget {c['today_budget_pct']:.0f}%. "
             f"Resets in {fmt_dur(c['reset_in_s'])}.")
        if c["critical"] and c["exhaust_ts"]:
            s += f" At this rate you run dry {fmt_when(c['exhaust_ts'])}."
        return s

    L = []
    head = {"behind": "BEHIND pace - you have room to spend",
            "ahead": "AHEAD of pace - ease off",
            "at_risk": "AT RISK - fine for the week so far, but today's rate runs it dry early",
            "on_pace": "ON pace"}[verdict]
    L.append(f"Claude Code weekly limit: {head}")
    L.append("")
    ratio_bit = ""
    if c.get("pace_ratio"):
        ratio_bit = f" That is {c['pace_ratio'] * 100:.0f}% of the expected pace."
    L.append(f"Used {w:.0f}% of the weekly limit and {el:.0f}% of the week has passed "
             f"({d:+.1f}pp against the clock).{ratio_bit}")
    L.append(f"Resets {fmt_when(c['reset_ts'])}, {fmt_dur(c['reset_in_s'])} from now. "
             f"{c['remaining_pct']:.0f}% left to spend.")

    if c["stale_reset"]:
        L.append("Note: the last recorded sample is older than the current reset, "
                 "so these numbers may lag until a Claude Code session refreshes them.")

    L.append("")
    L.append(f"Budget for today: about {c['today_budget_pct']:.0f}% more "
             f"(i.e. finish the day near {c['today_target_total_pct']:.0f}% overall). "
             f"Weighted by the hours you actually work, not a flat split.")

    rate = c["burn_rate_used"]
    if rate:
        L.append(f"Recent burn: {rate:.2f}% per hour of active work "
                 f"(you average {c['active_hours_per_day']:.1f} active hours a day).")
        mh = model_hours(c)
        if mh:
            bits = []
            for name, hours, r in mh:
                if hours is None:
                    bits.append(f"{name} (no measurable burn yet)")
                else:
                    bits.append(f"{hours:.1f}h of {name} ({r:.2f}%/h)")
            L.append("Today's budget is worth roughly: " + ", or ".join(bits) + ".")
        else:
            L.append("Not enough per-model history yet to split that into "
                     "per-model hours; the figure above is across all models.")
        if c["critical"] and c["exhaust_ts"]:
            L.append(f"WARNING: at this rate you hit 100% {fmt_when(c['exhaust_ts'])}, "
                     f"which is {fmt_dur(c['reset_ts'] - c['exhaust_ts'])} before the reset. "
                     f"Slow down or move routine work to a cheaper model.")
        elif c.get("projected_end_pct") is not None:
            p_end = c["projected_end_pct"]
            if p_end >= 97:
                L.append(f"On this trajectory you finish the week at about "
                         f"{min(p_end, 100):.0f}% - right on target.")
            else:
                L.append(f"On this trajectory you only finish the week at about "
                         f"{p_end:.0f}%, leaving roughly {100 - p_end:.0f}% unused. "
                         f"That is money already paid for, so lean into the heavier "
                         f"model or take on more.")
    else:
        n = c["samples"]
        L.append(f"Burn rate not measurable yet ({c['burn']['overall_active_hours']:.1f}h "
                 f"of active work recorded, {n} sample{'' if n == 1 else 's'}). "
                 f"It sharpens as the ledger fills, then this line becomes "
                 f"per-model hours.")

    if c["five_hour_used_pct"] is not None:
        h5 = c["five_hour_used_pct"]
        note = "not a constraint right now"
        if h5 >= 80:
            note = "this is your immediate blocker, not the weekly limit"
        elif h5 >= 50:
            note = "watch it, it may bite before the weekly limit does"
        extra = ""
        if c["five_hour_reset_in_s"] is not None:
            extra = f", resets in {fmt_dur(c['five_hour_reset_in_s'])}"
        L.append("")
        L.append(f"5-hour window: {h5:.0f}% used{extra} - {note}.")

    L.append("")
    if verdict == "behind":
        L.append("Verdict: use it freely. Leaving the allowance unspent is the waste here.")
    elif verdict == "at_risk":
        L.append("Verdict: you have week-level headroom, but not at today's rate. "
                 "Keep going only if you can afford the quiet days, otherwise move "
                 "routine work to a cheaper model.")
    elif verdict == "ahead":
        L.append("Verdict: hold back on heavy work, or switch routine work to a cheaper "
                 "model, until the clock catches up.")
    else:
        L.append("Verdict: carry on, you are tracking the clock well.")

    if c["sample_age_s"] > 3600:
        L.append(f"(Data is {fmt_dur(c['sample_age_s'])} old - open a Claude Code "
                 f"session to refresh it.)")

    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser(description="Claude Code weekly limit pace")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--oneline", action="store_true", help="single-line summary")
    args = ap.parse_args()

    c = compute()
    if args.json:
        print(json.dumps(c, indent=2))
        return 0 if c.get("ok") else 1
    print(render(c, oneline=args.oneline))
    return 0 if c.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
