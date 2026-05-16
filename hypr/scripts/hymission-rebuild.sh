#!/bin/bash
# Rebuild the patched hymission (rolle/0.55-fixes = upstream + our local
# patches) from source and install it into hyprpm's plugin cache.
#
# Why this exists: hymission needs custom patches that aren't upstreamed
# (config defaults, hyprbars titlebar suppression, etc). hyprpm only knows
# how to build upstream master, so `hyprpm update` would drop our patches.
# This script rebuilds OUR branch against the CURRENT Hyprland headers and
# installs the result, so the patched plugin survives Hyprland upgrades.
#
# Run manually after a Hyprland or hymission update, or let
# hyprpm-ensure.sh invoke it automatically on a detected Hyprland version
# change. It does NOT hot-swap into a running compositor (that has crashed
# the desktop repeatedly). It only writes the cache; the new .so is picked
# up on the next clean Hyprland start.
#
# Exit codes: 0 ok / 1 precondition failed / 2 build failed.

set -euo pipefail

REPO="$HOME/Projects/hymission"
BRANCH="rolle/0.55-fixes"
CACHE="/var/cache/hyprpm/$USER/hymission/hymission.so"

log() { printf '[hymission-rebuild] %s\n' "$*"; }
die() { log "$*" >&2; exit "${2:-1}"; }

[ -d "$REPO/.git" ] || die "no hymission repo at $REPO"
[ -d "$(dirname "$CACHE")" ] || die "hymission not installed via hyprpm ($CACHE missing)"
command -v cmake >/dev/null || die "cmake not on PATH"

cd "$REPO"

# Refuse to clobber in-progress work in the repo.
if ! git diff --quiet || ! git diff --cached --quiet; then
    die "hymission repo has uncommitted changes; commit/stash before rebuild" 1
fi

log "checkout $BRANCH"
git fetch origin "$BRANCH" 2>/dev/null || true
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH" 2>/dev/null || log "no fast-forward pull (offline or diverged) - building local $BRANCH"

log "fresh cmake configure (avoids stale headersRoot include cache)"
rm -rf build-cmake
cmake -DCMAKE_BUILD_TYPE=Release -B build-cmake >/dev/null

log "build"
if ! cmake --build build-cmake 2>&1 | tail -1; then
    die "build failed - NOT touching the cache" 2
fi

[ -f build-cmake/libhymission.so ] || die "build produced no libhymission.so" 2

log "install into hyprpm cache (sudo)"
sudo cp build-cmake/libhymission.so "$CACHE"
sudo sed -i 's|enabled = false|enabled = true|' "$(dirname "$CACHE")/state.toml" 2>/dev/null || true

log "done. New plugin is staged - it loads on the NEXT clean Hyprland start."
log "Do NOT hyprpm enable/reload it into the running session."
