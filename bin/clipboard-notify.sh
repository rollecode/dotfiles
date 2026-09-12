#!/usr/bin/env bash
# Notify on each Wayland clipboard update. wl-paste --watch pipes the new
# content to stdin. No cliphist: DMS persists history, this only notifies.
set -u

body=$(cat)
[ -n "$body" ] || exit 0

# One-line preview, capped so a large selection cannot flood the daemon.
preview=$(printf '%s' "$body" | tr '\n\t' '  ' | tr -s ' ' | cut -c1-100)
[ -n "$preview" ] || exit 0

exec notify-send -a foot -c clipboard 'Copied' "$preview"
