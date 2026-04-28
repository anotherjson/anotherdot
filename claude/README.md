# claude

[Claude Code] config. Deployed via copy, not stow — Claude Code has
[known symlink bugs (#764)](https://github.com/anthropics/claude-code/issues/764)
where symlinked `CLAUDE.md` becomes invisible and `settings.json` causes
permission failures.

[Claude Code]: https://github.com/anthropics/claude-code

## Workflow

The `dots` alias (defined in `zsh/.zshrc`) wraps the justfile recipes:

```zsh
dots claude-status   # one-line summary of what differs between repo and ~/.claude/
dots claude-diff     # full diff
dots claude-pull     # copy live ~/.claude/ → repo (after editing in place)
dots claude-deploy   # copy repo → ~/.claude/
```

Edit live in `~/.claude/` (so Claude Code picks up changes immediately), then
`dots claude-pull` to commit them back to the repo.

## Layout

| Path | What it is |
|------|------------|
| `CLAUDE.md` | Global conventions injected into every Claude Code session |
| `settings.json` | Env vars, tool permissions (allow/deny), hook registration, status line, MCP servers — committed |
| `settings.local.json` | Machine-specific overrides — gitignored (`.gitignore` excludes `claude/settings.local.json`) |
| `statusline-command.sh` | Custom shell script that renders the status line |
| `starship.toml` | Starship config used by the status line script |
| `agents/` | Subagent personas (`.md` files; the filename is the agent name) |
| `hooks/` | Shell scripts wired to Claude Code lifecycle events via `settings.json` |
| `skills/` | Custom slash commands — each in `<name>/SKILL.md` |

## Adding things

**Agent**: drop `agents/<agent-name>.md`. Front-matter declares its tools and
description; the body is the system prompt. Available immediately on next
`dots claude-deploy`.

**Skill**: create `skills/<skill-name>/SKILL.md`. Front-matter declares the
trigger description; body is the instruction set. Invoked as
`/<skill-name>` in Claude Code.

**Hook**: add the script under `hooks/` (chmod +x), then register it in
`settings.json` under the relevant lifecycle event:

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [{ "type": "command", "command": "bash /home/anotherjson/.claude/hooks/<script>.sh" }]
    }
  ]
}
```

Existing hook: `hooks/block-sensitive-files.sh` — refuses Write/Edit on
`*.env`, `*credentials*`, `*secret*`, `*.pem`, `*.key`.
