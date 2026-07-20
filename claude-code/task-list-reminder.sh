#!/bin/bash
# UserPromptSubmit hook: injects the task-list rule into context on every prompt,
# so it cannot be forgotten mid-session the way a CLAUDE.md line can.
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"TASK LIST DISCIPLINE (enforced every turn): if this request involves more than one step, or continues earlier multi-step work, create tasks with TaskCreate BEFORE doing anything else, in the order given. Mark each in_progress when starting it and completed when finished. Print the current task list in your response every time it changes. Do not skip this because the work seems small; skip it only for a single trivial action or a purely conversational reply."}}
EOF
