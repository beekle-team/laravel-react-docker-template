---
name: simplify
description: Use when simplifying recently changed or explicitly selected code without changing behavior, while removing dead code, unnecessary nesting, duplication, and unclear naming.
---

# Simplification workflow

1. Resolve the explicit target, or use only files changed by the current work when no target is given.
2. Read the relevant `.ai/rules/**` files and existing tests before editing.
3. Preserve observable behavior, public interfaces, validation, authorization, and error semantics.
4. Remove dead imports, variables, functions, comments, and unreachable code; flatten unnecessary nesting; improve unclear names; consolidate proven duplication without premature abstraction.
5. Keep the diff narrow and review it specifically for accidental behavior changes.
6. Run focused tests and the change-appropriate Quality Gates from `AGENTS.md`.

Do not add features, introduce speculative design patterns, hand-edit generated TypeScript or Wayfinder output, or replace readable domain code with clever compression.
