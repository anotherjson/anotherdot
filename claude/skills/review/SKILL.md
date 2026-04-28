---
name: review-code
description: Review staged changes or a PR for bugs, style, and improvements
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
user-invocable: true
model: inherit
---

Perform a thorough code review.

If $ARGUMENTS is a PR number or URL, review that PR using `gh pr diff`.
Otherwise, review the current staged changes or working tree diff.

Review criteria:

1. **Correctness**: Logic errors, edge cases, off-by-one, null/None handling
2. **Security**: Credential exposure, injection, unsafe deserialization
3. **Style**: Functional patterns, naming, DRY, readability
4. **Performance**: Unnecessary allocations, N+1 queries, blocking calls
5. **Tests**: Are changes tested? Are tests meaningful?

Output format:

- Group findings by severity: CRITICAL, IMPORTANT, SUGGESTION
- Reference specific file:line_number
- Provide concrete fix suggestions
- End with a brief overall assessment
