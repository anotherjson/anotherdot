---
name: commit
description: Create a well-structured git commit with conventional format
allowed-tools: ["Bash", "Read", "Grep"]
user-invocable: true
disable-model-invocation: true
model: haiku
---

Create a git commit for the current changes. Default to a concise single-line
conventional commit and commit directly — do NOT propose-and-confirm.

Steps:
1. Run `git status` and `git diff --staged` (or `git diff` if nothing staged)
2. Determine type from the diff: feat, fix, refactor, docs, test, chore
3. Stage relevant files (never stage .env, credentials, or secrets)
4. Commit directly with `type(scope): description` (~60 chars on the title)
   - No proposal step. No confirmation prompt. Just commit.
   - Add a body only when a non-obvious "why" is worth recording (incident,
     surprising tradeoff, hidden constraint). Most commits don't need one.
   - If the user passed `$ARGUMENTS`, treat it as the message hint or a
     verbatim title to use.
5. Briefly report the resulting commit hash and `git status`.

$ARGUMENTS is an optional hint about what the commit is for.
