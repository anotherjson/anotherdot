---
name: pr
description: Create a GitHub PR with auto-generated summary from branch commits
allowed-tools: ["Bash", "Read", "Grep"]
user-invocable: true
model: haiku
---

Create a GitHub pull request for the current branch.

Steps:

1. Determine the base branch (usually main)
2. Run `git log main..HEAD --oneline` to see all commits
3. Run `git diff main...HEAD --stat` for changed files summary
4. Draft a PR title (<70 chars) and body with:
   - ## Summary (2-3 bullet points)
   - ## Changes (file-level summary)
   - ## Test plan (checklist)
5. Push the branch with `git push -u origin HEAD` if needed
6. Create the PR with `gh pr create`
7. Return the PR URL

$ARGUMENTS can specify the base branch or title hint.
