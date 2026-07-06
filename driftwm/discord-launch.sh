#!/usr/bin/env bash
# Discord launcher for driftwm autostart.
#
# Launched too early after login, Discord's renderer segfaults (exit 139)
# twice in a row at "Initializing voice engine" (audio stack still settling)
# and the app then exits permanently ("double crashed ... RIP"). A manual
# relaunch minutes later always works, so: retry with a settle delay.
#
# Retry is keyed on runtime, not exit code (Discord can exit 0 on the RIP
# path): any run shorter than HEALTHY_SECS is treated as a crash and
# relaunched, up to MAX_ATTEMPTS. A run longer than that counts as healthy,
# so a user quitting Discord normally is not fought by a respawn.

HEALTHY_SECS=120
MAX_ATTEMPTS=3

# Parity with the known-good DMS launcher path (xwayland-satellite pins :0).
export DISPLAY="${DISPLAY:-:0}"

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
    start=$(date +%s)
    discord "$@"
    ran=$(( $(date +%s) - start ))
    if [ "$ran" -ge "$HEALTHY_SECS" ]; then
        exit 0
    fi
    echo "discord-launch: attempt $attempt died after ${ran}s, retrying..." >&2
    sleep 15
done
echo "discord-launch: gave up after $MAX_ATTEMPTS attempts" >&2
exit 1
