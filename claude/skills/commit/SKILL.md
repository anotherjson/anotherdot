---
name: commit
description: Create a well-structured git commit with conventional format
allowed-tools: ["Bash", "Read", "Grep"]
user-invocable: true
disable-model-invocation: true
model: haiku
---

Create a git commit for the current changes.

Steps:
1. Run `git status` and `git diff --staged` (or `git diff` if nothing staged)
2. Analyze changes to determine type: feat, fix, refactor, docs, test, chore
3. Draft a conventional commit message: `type(scope): description`
4. Stage relevant files if needed (never stage .env, credentials, or secrets)
5. Show the proposed message and ask for confirmation
6. Commit with the approved message

$ARGUMENTS is an optional hint about what the commit is for.
