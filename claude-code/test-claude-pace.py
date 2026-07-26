#!/usr/bin/env python3
"""Exercise claude-pace.py against synthetic weeks.

The interesting cases only happen once a week (reset boundary) or on a bad week
(running dry on Thursday), so they are simulated rather than waited for.
"""

import json
import os
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
PACE = os.path.join(HERE, "claude-pace.py")


def week_reset_after(now):
    """Next Sunday 04:00 local, matching the real plan anchor."""
    dt = datetime.fromtimestamp(now)
    d = dt.replace(hour=4, minute=0, second=0, microsecond=0)
    while d.weekday() != 6 or d.timestamp() <= now:
        d += timedelta(days=1)
    return d.timestamp()


def build(tmp, weekly_pct, reset_ts, samples=None, h5=10, model="claude-opus-5"):
    latest_p = os.path.join(tmp, "latest.json")
    ledger_p = os.path.join(tmp, "ledger.jsonl")
    stats_p = os.path.join(tmp, "stats.json")

    now = int(time.time())
    latest = {"ts": now, "w": weekly_pct, "h5": h5,
              "wr": int(reset_ts), "hr": now + 1800, "model": model}
    with open(latest_p, "w") as fh:
        json.dump(latest, fh)

    with open(ledger_p, "w") as fh:
        for s in (samples or [latest]):
            fh.write(json.dumps(s) + "\n")

    # Real-ish activity distribution: quiet nights, busy afternoons/evenings.
    with open(stats_p, "w") as fh:
        json.dump({"hourCounts": {"0": 8, "1": 5, "2": 1, "9": 1, "11": 3,
                                  "12": 13, "13": 6, "14": 11, "15": 8,
                                  "16": 11, "17": 15, "18": 19, "19": 15,
                                  "20": 6, "21": 11, "22": 7, "23": 5}}, fh)

    env = dict(os.environ)
    env.update({"CLAUDE_PACE_LATEST": latest_p,
                "CLAUDE_PACE_LEDGER": ledger_p,
                "CLAUDE_PACE_STATS": stats_p})
    return env


def run(env, *args):
    return subprocess.run([sys.executable, PACE, *args], env=env,
                          capture_output=True, text=True)


def active_samples(now, reset_ts, start_pct, end_pct, hours, model):
    """A run of samples 5 minutes apart, so they count as active work."""
    out = []
    n = int(hours * 12)
    for i in range(n + 1):
        ts = int(now - (n - i) * 300)
        pct = start_pct + (end_pct - start_pct) * (i / max(1, n))
        out.append({"ts": ts, "w": round(pct), "h5": 20,
                    "wr": int(reset_ts), "hr": ts + 3600, "model": model})
    return out


def working_week(now, reset_ts, end_pct, days, hours_per_day, model,
                 start_pct=0):
    """A realistic week: a block of active work each day, usage climbing to end_pct.

    Burn projection converts a per-active-hour rate into calendar time using the
    observed active hours per day, so a fixture has to span real days or it
    implies someone who works 45 minutes a week.
    """
    out = []
    total_blocks = max(1, int(days))
    per_block = (end_pct - start_pct) / total_blocks
    for d in range(total_blocks):
        day_start = now - (total_blocks - d) * 86400
        lo = start_pct + per_block * d
        hi = start_pct + per_block * (d + 1)
        out.extend(active_samples(day_start + hours_per_day * 3600, reset_ts,
                                  lo, hi, hours_per_day, model))
    return out


def check(name, cond, detail=""):
    print(f"  {'PASS' if cond else '**FAIL**'}  {name}" + (f"  [{detail}]" if detail else ""))
    return cond


def main():
    now = time.time()
    ok = True

    with tempfile.TemporaryDirectory() as tmp:
        print("1. Fresh week, barely used (should be BEHIND, spend freely)")
        reset = week_reset_after(now)
        env = build(tmp, 2, reset)
        r = run(env, "--json")
        c = json.loads(r.stdout)
        ok &= check("verdict behind", c["verdict"] == "behind", c["verdict"])
        ok &= check("not critical", c["critical"] is False)
        ok &= check("today budget > 0", c["today_budget_pct"] > 0,
                    f"{c['today_budget_pct']:.1f}%")

    with tempfile.TemporaryDirectory() as tmp:
        print("2. Thursday burnout: 85% used with days left (AHEAD + critical)")
        # Reset still ~3 days out, but nearly everything already spent, off the
        # back of four real working days rather than one short burst.
        reset = now + 3 * 86400
        samples = working_week(now, reset, 85, days=4, hours_per_day=6.0,
                               model="claude-opus-5")
        env = build(tmp, 85, reset, samples=samples)
        r = run(env, "--json")
        c = json.loads(r.stdout)
        ok &= check("verdict ahead", c["verdict"] == "ahead", c["verdict"])
        ok &= check("burn rate measured", c["burn_rate_used"] is not None,
                    str(c["burn_rate_used"]))
        ok &= check("critical flagged", c["critical"] is True,
                    f"active_h/day={c['active_hours_per_day']:.1f}")
        ok &= check("exhausts before reset",
                    c["exhaust_ts"] is not None and c["exhaust_ts"] < c["reset_ts"])
        txt = run(env).stdout
        ok &= check("warns in prose", "WARNING" in txt)

    with tempfile.TemporaryDirectory() as tmp:
        print("3. Per-model hours: cheap model vs expensive model")
        reset = now + 4 * 86400
        # Opus burns 4%/h, Fable 1%/h, both with enough active time to qualify.
        s1 = active_samples(now - 5 * 3600, reset, 10, 22, 3.0, "claude-opus-5")
        s2 = active_samples(now, reset, 22, 25, 3.0, "claude-fable-5")
        env = build(tmp, 25, reset, samples=s1 + s2, model="claude-fable-5")
        r = run(env, "--json")
        c = json.loads(r.stdout)
        models = c["burn"]["models"]
        ok &= check("two models measured", len(models) == 2, str(list(models)))
        if len(models) == 2:
            opus = models.get("claude-opus-5", {}).get("rate")
            fable = models.get("claude-fable-5", {}).get("rate")
            ok &= check("opus burns faster than fable", opus > fable,
                        f"opus={opus:.2f}%/h fable={fable:.2f}%/h")
        txt = run(env).stdout
        ok &= check("prose gives per-model hours", "of Opus 5" in txt and "of Fable 5" in txt)
        ok &= check("cheapest listed first", txt.find("Fable 5") < txt.find("Opus 5"))

    with tempfile.TemporaryDirectory() as tmp:
        print("4. Reset boundary: sample from a window that already reset")
        env = build(tmp, 90, now - 3600)  # reset was an hour ago
        r = run(env, "--json")
        c = json.loads(r.stdout)
        ok &= check("stale reset detected", c["stale_reset"] is True)
        txt = run(env).stdout
        ok &= check("says numbers may lag", "may lag" in txt)

    with tempfile.TemporaryDirectory() as tmp:
        print("5. Exactly on pace mid-week")
        reset = now + 3.5 * 86400
        env = build(tmp, 50, reset)
        r = run(env, "--json")
        c = json.loads(r.stdout)
        ok &= check("verdict on_pace", c["verdict"] == "on_pace",
                    f"{c['verdict']} delta={c['pace_delta_pp']:.1f}")

    with tempfile.TemporaryDirectory() as tmp:
        print("6. No data at all")
        env = dict(os.environ)
        env.update({"CLAUDE_PACE_LATEST": os.path.join(tmp, "nope.json"),
                    "CLAUDE_PACE_LEDGER": os.path.join(tmp, "nope.jsonl"),
                    "CLAUDE_PACE_STATS": os.path.join(tmp, "nope.json")})
        r = run(env)
        ok &= check("degrades gracefully", "no pace data yet" in r.stdout, r.stdout.strip()[:60])
        ok &= check("non-zero exit", r.returncode != 0)

    print()
    print("ALL PASS" if ok else "SOME FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
