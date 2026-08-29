---
name: commit
description: Use when the user asks to create a git commit; inspect the diff, run change-appropriate quality gates, protect secrets, and write a Conventional Commit message.
---

# Commit workflow

1. Inspect `git status`, staged and unstaged diffs, and recent commit style.
2. Keep unrelated user changes out of the commit. Never stage secrets such as `.env` files or credentials.
3. Run the change-appropriate Quality Gates from `AGENTS.md`. Do not commit while a required gate fails.
4. Stage only the intended files and review the staged diff, including generated or deleted files.
5. Create a Conventional Commit whose type and optional scope describe the change: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, or `style`.
6. Verify the resulting commit and report its hash and subject.

Split unrelated purposes into separate commits. Include tests for new behavior and explain any required gate that cannot run.
