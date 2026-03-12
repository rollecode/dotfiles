## Tool preferences

- Always prefer MCP tools over direct file operations. Use Obsidian MCP to search/read notes instead of grepping ~/Documents/Brain dump/. Use Linear MCP instead of searching local files. Use Sunsama MCP instead of curl. Use Help Scout MCP for ticket data. Use GitHub MCP for commits/releases. MCP tools are faster and more reliable than raw file searches.
- When running slash commands (/plan-today, /plan-week, /finish-day), use MCP tools exclusively for data gathering. Never fall back to grepping or reading files directly unless an MCP server is confirmed down.
- For Obsidian vault content, always use the Obsidian MCP (mcp-obsidian) tools, not Grep/Read on ~/Documents/Brain dump/

## Commits and code style

- Never use Claude watermark in commits (FORBIDDEN: "Co-Authored-By")
- No emojis in commits or code
- Use present tense in commits
- Use sentence case for headings

## Task completion tracking

- When the user says something is done, finished, or indicates a task is completed (e.g. "done with X", "finished the meeting", "closed that ticket"), update BOTH:
  1. Today's CHANGELOG.md entry (~/Documents/Brain dump/CHANGELOG.md) - append a `* ` bullet in English, present tense
  2. Today's daily plan if it exists (~/Documents/Brain dump/claude-mcp-daily-plans/) - change the matching task checkbox from `- [ ]` or `- [>]` to `- [x]`
- This applies whether the user uses `/done` or just mentions completion in conversation

## Communication

- Write in English by default
- Finnish date format (d.M.yyyy)
- Never use emdashes, use regular dashes
- No fluff, be concise
