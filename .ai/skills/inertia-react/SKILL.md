---
name: inertia-react
description: Use when building Laravel and React behavior with Inertia, Laravel Data generated types, forms, navigation, Precognition, deferred props, polling, prefetching, or infinite scroll.
---

# Inertia React workflow

Read the relevant files under `.ai/rules/frontend/**`, plus `.ai/rules/laravel/inertia-props.md` and `.ai/rules/type-safety.md`, before making changes.

1. Inspect the installed package versions and nearby implementation before selecting an API.
2. Use generated Wayfinder functions from `@/routes` and `@/actions` where available; do not add Ziggy or hand-edit generated files.
3. Define server-to-client data with Laravel Data and generated TypeScript declarations instead of parallel manual interfaces.
4. Keep Pages as Inertia entries and place domain implementation under `features/{feature}/`; share only proven cross-feature code.
5. Use Inertia form, navigation, deferred-prop, polling, prefetch, or Precognition APIs only after confirming the installed version and an existing local pattern.
6. Run the quality gates required by `AGENTS.md`.
