---
name: update-plan
description: Update the current plan file with what was done and what is left to do
allowed-tools: ["Bash", "Read", "Edit", "Grep"]
user-invocable: true
model: inherit
---

Update the most-recently-active plan file under `~/.claude/plans/` to reflect what's
been completed and what remains.

Steps:

1. Locate the current plan: `eza -1 --sort=modified --reverse ~/.claude/plans/*.md | head -1`.
   If `$ARGUMENTS` looks like a path or filename, use that instead.
2. Read the plan and identify its structure — usually a Status summary table near the
   top followed by Phase sections.
3. Cross-reference recent work:
   - `git log --oneline -20` for recent commits
   - `git status` for uncommitted in-progress work
   - The current conversation context for user-verified or skipped items
4. For each phase in the plan:
   - If a related commit landed, mark it ✅ Shipped with the commit hash.
   - If user-verified empirically, note that in the Outcome column.
   - If complete with no code change (research/decision phase), mark ✅ Complete with `—` in the Commit column.
   - If still open, leave or refine the substatus.
5. Update the Status summary table with the latest outcomes and current date.
6. If a new follow-up phase clearly emerged from recent work, append it at the bottom
   with at least Context + Approach.
7. Do NOT commit. Just edit the plan file.
8. Briefly report: which plan was updated, which phases changed status, what's still pending.

$ARGUMENTS is optional — pass a plan filename to target a specific plan instead of the most recent.
