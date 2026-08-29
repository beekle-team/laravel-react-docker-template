---
name: bdd
description: Use when defining or implementing a Laravel Feature behavior from Gherkin requirements under docs/specs, including scenario approval and one-scenario Red-Green-Refactor.
---

# BDD workflow

Follow `.ai/rules/testing.md`; it is authoritative for requirements, scenario format, and test boundaries.

## Required sequence

1. Resolve the feature name from the request and inspect `docs/specs/<feature>/requirements.md`.
2. If requirements or Gherkin scenarios are missing, gather the missing behavior and draft them before writing a Feature test.
3. Present new or changed requirements and scenarios for user approval before saving or implementing them.
4. Before generating tests, list the target test file and scenarios and obtain approval.
5. Convert one approved scenario at a time to a Pest Feature test using `scenario()` from `src/tests/Support/Gwt/Scenario.php`.
6. Run that scenario through Red, Green, and Refactor before starting the next scenario.

Place specifications at `docs/specs/<feature>/requirements.md` and Feature tests under `src/tests/Feature/`. Run the narrowest relevant Pest command first, then the quality gates required by `AGENTS.md`.

Do not invent unapproved behavior, write Feature tests without Gherkin requirements, or implement multiple failing scenarios at once.
