Log a completed task to today's entry in the Life changelog at ~/Documents/Brain dump/CHANGELOG.md AND update today's daily plan if it exists.

The user's input: $ARGUMENTS

Instructions:
1. Read ~/Documents/Brain dump/CHANGELOG.md (just the first 30 lines to find today's entry)
2. Find today's date entry (format: ### x.y.z: YYYY-MM-DD)
3. Append a new bullet point (* ) with the task description at the end of today's bullet list. Always write in English and use present tense ("Fix bug", not "Fixed bug").
4. If the user mentions a Linear issue ID (like DEV-123, RAD-456, PIEN-789), add ", Closes ISSUE-ID" at the end
5. If the user mentions multiple Linear issues, list them all: "Closes DEV-123, DEV-456"
6. If the user mentions a Help Scout ticket, write in English and link to it: "Replied to Help Scout ticket #12345 - Subject"
7. If the user mentions who they worked with or had a meeting with, include that info, e.g. "Daily standup with Juha and William"
8. Do not duplicate entries that are already listed
9. Keep the description concise - match the style of existing entries (short, action-oriented)
10. If $ARGUMENTS is empty, ask what task was completed
11. After updating CHANGELOG.md, check if today's daily plan exists in ~/Documents/Brain dump/claude-mcp-daily-plans/. If it does, find the matching task in the plan and change its checkbox from `- [ ]` or `- [>]` to `- [x]` to mark it as completed.
