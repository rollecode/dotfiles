# Claude Code task list fix

Paste this to an agent whose task list does not work.

---

Set up the task list. Two separate problems, both fixed in `~/.claude/settings.json`:

```json
{
  "env": { "CLAUDE_CODE_ENABLE_TODO_TOOLS": "true" },
  "todoFeatureEnabled": true,
  "showExpandedTodos": true
}
```

- `env.CLAUDE_CODE_ENABLE_TODO_TOOLS` registers TaskCreate, TaskUpdate,
  TaskList and TaskGet. Claude Code disables them by default on opus >= 4.8,
  sonnet >= 5 and fable >= 5. It must be nested inside `env`, not top level.
- `todoFeatureEnabled` is the feature switch.
- `showExpandedTodos` keeps the list on screen, so CTRL+T is not needed.

Verified on Claude Code 2.1.234. Running sessions pick the keys up on a later
turn without a restart.

Then run ToolSearch with `select:TaskCreate,TaskUpdate,TaskList,TaskGet` and
rebuild the task list.

## If the tools still do not appear

1. `jq . ~/.claude/settings.json`
   Invalid JSON is ignored silently, so one stray comma undoes everything.
2. `jq '.env, .todoFeatureEnabled, .showExpandedTodos' ~/.claude/settings.json`
   If the flag sits at the top level instead of inside `.env`, it does nothing.
3. `cat .claude/settings.json .claude/settings.local.json 2>/dev/null`
   A project level file overrides the user one.
4. `CLAUDE_CODE_ENABLE_TODO_TOOLS=true claude -p 'list your tools' | grep -i taskcreate`
   Works this way but not from settings.json means the file is the problem.
5. ToolSearch again on the next turn. They arrive as deferred tools and can
   take a turn or two to register.

## If they never register

Write the list to disk and keep working. One JSON file per task at
`~/.claude/tasks/<session-id>/<id>.json`, keys exactly `id`, `subject`,
`description`, `activeForm`, `status` (pending, in_progress or completed),
`blocks`, `blockedBy`.

The session id is the newest `~/.claude/projects/<project>/<id>.jsonl`.

Never touch `.highwatermark`. It is a floor, and the visible list is the ids
above it, so raising it hides everything. These files load as real tasks the
moment the tools register.

## Always

Print the task table in the reply whenever it changes. That channel cannot
break, unlike CTRL+T.
