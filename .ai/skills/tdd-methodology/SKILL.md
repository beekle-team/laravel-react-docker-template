---
name: tdd-methodology
description: Use when implementing behavior with test-first development, Gherkin requirements, Pest Feature tests using scenario(), Vitest, or Playwright.
---

# TDD/BDD workflow

Read `.ai/rules/testing.md`, `.ai/rules/frontend/testing.md`, and `.ai/rules/testing/architecture-tests.md` before making changes.

1. Read the approved Gherkin Scenario in `docs/specs/{feature}/requirements.md` before changing Feature behavior.
2. Write one focused test and run it to confirm the expected failure.
3. Write the minimum implementation needed to make that test pass, then rerun it.
4. Refactor only while the test remains green; do not start another Scenario while the current one fails.
5. Use Pest Feature tests for HTTP/Inertia behavior, Vitest for components and hooks, and Playwright for multi-screen user flows.
6. Record implementation status in the active task or pull request; keep `requirements.md` focused on approved Gherkin behavior.
7. Run the quality gates required by `AGENTS.md`.
