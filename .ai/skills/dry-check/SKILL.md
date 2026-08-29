---
name: dry-check
description: Use when detecting or removing duplicated PHP, Laravel, React, or TypeScript code while avoiding premature or behavior-changing abstractions.
---

# DRY check workflow

Read `.ai/rules/laravel/model-layer-boundaries.md` and `.ai/rules/frontend/architecture.md` before making changes.

1. Identify the repeated behavior and every caller.
2. Read those sections in `references/guide.md` completely.
3. Consolidate only proven duplication without changing observable behavior.
4. Run the quality gates required by `AGENTS.md`.
