#!/bin/bash
# Appends a completed task entry to today's CHANGELOG.md in Obsidian
# Usage: append-changelog.sh "Task description, Closes DEV-123"
# Also works as a PostToolUse hook (reads JSON from stdin)

CHANGELOG="/Users/rolle/Documents/Brain dump/CHANGELOG.md"
TODAY=$(date +%Y-%m-%d)

ENTRY=""

# If argument provided, use it directly
if [[ -n "$1" ]]; then
  ENTRY="$1"
else
  # PostToolUse hook mode: read JSON from stdin
  INPUT=$(cat)
  TOOL_NAME=$(echo "$INPUT" | /usr/bin/python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', ''))
except: pass
" 2>/dev/null <<< "$INPUT")

  TOOL_INPUT=$(echo "$INPUT" | /usr/bin/python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(json.dumps(d.get('tool_input', {})))
except: pass
" 2>/dev/null <<< "$INPUT")

  TOOL_OUTPUT=$(echo "$INPUT" | /usr/bin/python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # tool_output can be a string containing JSON
    out = d.get('tool_output', '')
    if isinstance(out, str):
        try:
            parsed = json.loads(out)
            print(json.dumps(parsed))
        except:
            print(out)
    else:
        print(json.dumps(out))
except: pass
" 2>/dev/null <<< "$INPUT")

  # Handle sunsama_complete_task
  if echo "$TOOL_NAME" | grep -qi "sunsama.*complete"; then
    TASK_TITLE=$(/usr/bin/python3 -c "
import sys, json
try:
    d = json.loads(sys.argv[1])
    # Try common title fields
    for key in ['text', 'title', 'name']:
        if key in d and d[key]:
            print(d[key])
            break
except: pass
" "$TOOL_OUTPUT" 2>/dev/null)
    if [[ -n "$TASK_TITLE" ]]; then
      ENTRY="$TASK_TITLE"
    fi
  fi

  # Handle linear save_issue (status change to Done)
  if echo "$TOOL_NAME" | grep -qi "linear.*save_issue"; then
    RESULT=$(/usr/bin/python3 -c "
import sys, json
try:
    inp = json.loads(sys.argv[1])
    out = json.loads(sys.argv[2])
    status = inp.get('status', '') or ''
    if 'done' in status.lower() or 'closed' in status.lower() or 'completed' in status.lower():
        title = out.get('title', '') or inp.get('title', '') or ''
        identifier = out.get('identifier', '') or inp.get('identifier', '') or ''
        if title and identifier:
            print(f'{title}, Closes {identifier}')
        elif title:
            print(title)
except: pass
" "$TOOL_INPUT" "$TOOL_OUTPUT" 2>/dev/null)
    if [[ -n "$RESULT" ]]; then
      ENTRY="$RESULT"
    fi
  fi
fi

# Nothing to log
if [[ -z "$ENTRY" ]]; then
  exit 0
fi

# Check changelog exists
if [[ ! -f "$CHANGELOG" ]]; then
  exit 1
fi

# Find today's section and append
/usr/bin/python3 -c "
import sys

changelog_path = sys.argv[1]
today = sys.argv[2]
entry = sys.argv[3]
entry_line = f'* {entry}'

with open(changelog_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find today's header
today_idx = -1
for i, line in enumerate(lines):
    if line.strip().endswith(today) and line.strip().startswith('###'):
        today_idx = i
        break

if today_idx == -1:
    sys.exit(0)  # No entry for today

# Find end of today's section (next ### or EOF)
end_idx = len(lines)
for i in range(today_idx + 1, len(lines)):
    if lines[i].strip().startswith('### '):
        end_idx = i
        break

# Check for duplicates
for i in range(today_idx, end_idx):
    if lines[i].strip() == entry_line.strip():
        sys.exit(0)  # Already logged

# Find the last bullet line in today's section
last_bullet = today_idx
for i in range(today_idx + 1, end_idx):
    if lines[i].strip().startswith('* '):
        last_bullet = i

# Insert after last bullet
lines.insert(last_bullet + 1, entry_line + '\n')

with open(changelog_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
" "$CHANGELOG" "$TODAY" "$ENTRY"
