## Commits and code style

- 2 space indents
- One logical change per commit
- Keep commit messages concise (one line), use sentence case
- Commit each change
- Update CHANGELOG.md after each change
- Use present tense in commits and CHANGELOG.md
- Use sentence case for headings (not Title Case)
- Never use bold text as headings, use proper heading levels instead
- Always add an empty line after headings
- No formatting in CHANGELOG.md except `inline code` and when absolute necessary
- Use `*` as bullets in CHANGELOG.md
- Never use Claude watermark in commits (FORBIDDEN: "Co-Authored-By")
- No emojis in commits or code
- Keep CHANGELOG.md date up to date when adding entries
- Never use "====" separators or underlines with "=", if you must use them, prefer dash or single line separators or headings that match the text width

## Versioning

Files that contain version numbers and must be updated on each release:

- `README.md` - badge in line 3 (`version-X.Y.Z`)
- `CHANGELOG.md` - new entry at the top

## Claude Code workflow

- Always add tasks to the Claude Code to-do list and keep it up to date.
- Review your to-do list and prioritize before starting.
- If new tasks come in, don't jump to them right away—add them to the list in order of urgency and finish your current work first.
- Do not ever guess features, always proof them via looking up official docs, GitHub code, issues, if possible.
- When looking things up, do not use years in search terms like 2024 or 2025.
