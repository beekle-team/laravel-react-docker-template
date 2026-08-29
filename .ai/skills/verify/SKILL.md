---
name: verify
description: Use when verifying the repository or a completed change with the quality gates required by AGENTS.md, including targeted repair and rerun of failed checks.
---

# Verification workflow

Treat `AGENTS.md` as the authoritative command list and `.ai/rules/testing.md` as the authoritative test boundary.

1. Inspect the changed paths and select every applicable quality gate.
2. Run independent backend and frontend checks concurrently when the environment supports it.
3. In quick mode, run lint, static analysis, generated-artifact consistency, and type checks while skipping behavioral test suites.
4. In full mode, also run relevant Pest, Vitest, and Playwright suites; include E2E when user flows changed.
5. Diagnose failures from their first useful error, make only in-scope repairs, and rerun the failed command.
6. Finish only after all required gates pass. Report commands, outcomes, and any warning or unavailable check separately.

Never hide a failure behind a later successful command or claim success from stale output.
