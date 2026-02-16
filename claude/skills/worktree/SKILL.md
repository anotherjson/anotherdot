---
name: worktree
description: Manage git worktrees — create, list with context, and clean up stale ones
allowed-tools: ["Bash", "Read"]
user-invocable: true
disable-model-invocation: true
model: haiku
---

Manage git worktrees for the current repository.

Parse $ARGUMENTS to determine the subcommand:

## Subcommands

### `new <branch-name> [base-ref]` (default if just a name is given)
1. Determine the repo root with `git rev-parse --show-toplevel`
2. Derive the repo basename (e.g. `my-project`)
3. Create worktree at `../<repo-basename>.<branch-name>/` from `base-ref` (default: `main`)
4. Run: `git worktree add ../<repo-basename>.<branch-name> -b <branch-name> <base-ref>`
5. Print the path and suggest `cd` command

### `list`
1. Run `git worktree list --porcelain` and parse output
2. For each worktree, show:
   - Path
   - Branch name
   - Last commit (short hash + subject via `git log -1 --format='%h %s'`)
   - Dirty status (`git -C <path> status --porcelain | head -1`)
3. Format as a clean table

### `clean`
1. Run `git worktree list --porcelain` to find all worktrees
2. Identify stale worktrees (missing directories or branches deleted from remote)
3. Run `git worktree prune` to remove stale entries
4. List what was pruned
5. Optionally suggest worktrees whose remote branches are gone

If $ARGUMENTS is empty, default to `list`.
