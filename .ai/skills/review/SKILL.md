---
name: review
description: Use when reviewing a branch, pull request, commit, or file set for correctness, security, architecture, type safety, regressions, and missing tests.
---

# Review workflow

Resolve the requested target. If none is provided, compare the current branch with its merge base against the default branch.

1. Read `AGENTS.md` and all `.ai/rules/**` files relevant to the changed paths.
2. Inspect the complete diff and surrounding code, not only isolated changed lines.
3. Check correctness, regressions, security and authorization, error handling, Laravel boundaries, React architecture, generated-type safety, and test coverage.
4. Run focused checks when they can confirm or reject a suspected issue.
5. Report only actionable findings, ordered by severity: critical, major, then minor.

Each finding must include a file and line, the concrete failure mode, why it matters, and the smallest appropriate correction. Keep questions and residual test risks separate. If there are no findings, say so explicitly and list any verification gaps.
