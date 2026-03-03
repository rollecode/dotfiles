Log a completed task to today's entry in the Life changelog at ~/Documents/Brain dump/CHANGELOG.md.

The user's input: $ARGUMENTS

Instructions:
1. Read ~/Documents/Brain dump/CHANGELOG.md (just the first 30 lines to find today's entry)
2. Find today's date entry (format: ### x.y.z: YYYY-MM-DD)
3. Append a new bullet point (* ) with the task description at the end of today's bullet list
4. If the user mentions a Linear issue ID (like DEV-123, RAD-456, PIEN-789), add ", Closes ISSUE-ID" at the end
5. If the user mentions multiple Linear issues, list them all: "Closes DEV-123, DEV-456"
6. Do not duplicate entries that are already listed
7. Keep the description concise — match the style of existing entries (short, action-oriented)
8. If $ARGUMENTS is empty, ask what task was completed
