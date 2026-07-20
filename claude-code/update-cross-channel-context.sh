#!/bin/bash
# Updates the Son of Anton cross-channel handoff file with "Claude Code" as
# the last active channel. Runs on every Stop event so Slack and Telegram
# heartbeats know to back off while the user is talking to the CLI.
#
# Only patches "## Last channel" and "## Last interaction". Leaves Current
# topic, Recent conversation, Pending actions, Recent NanoClaw messages
# sections untouched.

set -u

f="$HOME/Documents/Brain dump/Son of Anton - Cross-channel context.md"
[ -f "$f" ] || exit 0

now=$(date '+%Y-%m-%d %H:%M:%S %Z')

python3 - "$f" "$now" <<'PY' 2>/dev/null || exit 0
import sys, re, pathlib
path = pathlib.Path(sys.argv[1])
now = sys.argv[2]
text = path.read_text()
text = re.sub(r'(## Last channel\n\n)[^\n]*', r'\1Claude Code', text, count=1)
text = re.sub(r'(## Last interaction\n\n)[^\n]*', r'\g<1>' + now, text, count=1)
path.write_text(text)
PY

exit 0
