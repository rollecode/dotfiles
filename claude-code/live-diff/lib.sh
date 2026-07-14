#!/usr/bin/env bash
# Shared helpers. Kept POSIX-ish so this survives macOS, Arch and Ubuntu server alike.

# Where the live stream is written. Override with CC_LIVE_LOG.
# Deliberately outside ~/.claude/live-diff: that path is a symlink into the dotfiles repo,
# and the stream carries diffs of whatever you happen to be editing. It must never land there.
cc_log() { printf '%s' "${CC_LIVE_LOG:-$HOME/.claude/live-diff-stream.log}"; }

# Stable, collision-free filename for an arbitrary absolute path.
# shasum (macOS) / sha1sum (most Linux) / md5sum, with a dumb fallback.
cc_hash_path() {
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum | cut -d' ' -f1
  elif command -v sha1sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha1sum | cut -d' ' -f1
  elif command -v md5sum >/dev/null 2>&1; then
    printf '%s' "$1" | md5sum | cut -d' ' -f1
  else
    printf '%s' "$1" | tr '/ ' '%_'
  fi
}

cc_snapdir() { printf '%s' "${TMPDIR:-/tmp}/cc-live-diff/$1"; }
