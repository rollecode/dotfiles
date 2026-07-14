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

# Tokyo Night. The palette, so the hexes below are readable rather than magic.
CC_TN_PURPLE="#bb9af7"   # hunk headers, the accent the whole stream is tuned around
CC_TN_RED="#f7768e"
CC_TN_GREEN="#9ece6a"
CC_TN_COMMENT="#565f89"
CC_TN_GUTTER="#414868"
CC_TN_ADD_BG="#20303b"   # git add background from the upstream theme
CC_TN_DEL_BG="#37222c"   # git delete background
CC_TN_ADD_EMPH="#2c5a66" # the changed words within a line, not the whole line
CC_TN_DEL_EMPH="#713137"

# Flags are passed explicitly rather than through [delta] in ~/.gitconfig, so the stream
# looks the same on a machine whose gitconfig we do not control.
# File and hunk headers are omitted: emit.sh prints its own, and delta's would duplicate them.
cc_delta_args() {
  printf '%s\n' \
    --paging=never \
    --syntax-theme=tokyonight_night \
    --file-style=omit \
    --hunk-header-style="$CC_TN_PURPLE bold" \
    --hunk-header-decoration-style="$CC_TN_GUTTER" \
    --minus-style="syntax $CC_TN_DEL_BG" \
    --minus-emph-style="syntax $CC_TN_DEL_EMPH" \
    --plus-style="syntax $CC_TN_ADD_BG" \
    --plus-emph-style="syntax $CC_TN_ADD_EMPH" \
    --line-numbers \
    --line-numbers-minus-style="$CC_TN_RED" \
    --line-numbers-plus-style="$CC_TN_GREEN" \
    --line-numbers-zero-style="$CC_TN_COMMENT" \
    --line-numbers-left-style="$CC_TN_GUTTER" \
    --line-numbers-right-style="$CC_TN_GUTTER" \
    --zero-style=syntax
}
