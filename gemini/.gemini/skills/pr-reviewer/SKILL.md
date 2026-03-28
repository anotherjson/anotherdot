---
name: pr-reviewer
description: A generic skill that reviews code in a GitHub Pull Request and automatically posts inline comments on specific lines using the GitHub CLI (`gh`). It defaults to leaving standard code review comments without requesting changes or approving.
---

## instructions
1. **Identify Target:** Determine the target PR number and repository. If the user does not provide a PR number, execute `gh pr status` to find the PR associated with the current branch.
2. **Extract Repository Context:** Execute `gh repo view --json owner,name -q '{owner: .owner.login, repo: .name}'` to determine the `{owner}` and `{repo}` names.
3. **Fetch Diff:** Retrieve the patch diff for the target PR by executing `gh pr diff <number> --patch`.
4. **Analyze Code:** Perform a standard code review on the diff, focusing on architectural improvements, potential bugs, edge cases, readability, and best practices. Do not focus exclusively on security unless specifically asked.
5. **Format Payload:** Construct the review feedback into a specific JSON structure required by the GitHub API. The `event` MUST default to `COMMENT`.
   ```json
   {
     "body": "General review summary message here.",
     "event": "COMMENT",
     "comments": [
       {
         "path": "path/to/modified/file.ext",
         "line": 123,
         "body": "**Suggestion:** Detailed feedback..."
       }
     ]
   }
   ```
6. **Execute:** Write the formatted JSON payload to a temporary file (e.g., `pr_review_payload.json`) in the current directory.
7. **Submit:** Post the inline review by executing the following command:
   `gh api --method POST -H "Accept: application/vnd.github+json" /repos/{owner}/{repo}/pulls/{pull_number}/reviews --input pr_review_payload.json`
8. **Cleanup:** Delete the temporary JSON file (`pr_review_payload.json`).
