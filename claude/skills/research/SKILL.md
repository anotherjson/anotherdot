---
name: research
description: Research a topic online and summarize findings
allowed-tools: ["WebSearch", "WebFetch", "Read", "Write"]
user-invocable: true
model: inherit
---

Research a topic thoroughly using web search and present organized findings.

Steps:

1. Break $ARGUMENTS into 2-3 targeted search queries
2. Search the web for each query
3. Fetch and read the most relevant results (up to 5 sources)
4. Synthesize findings into a structured summary with:
   - Key findings
   - Comparison of approaches (if applicable)
   - Recommended approach with rationale
   - Source links

Prefer official documentation and recent sources (current and prior year). Cross-reference claims across multiple sources.
