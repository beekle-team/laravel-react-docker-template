# AI-DLC and Spec-Driven Development

Kiro-style Spec Driven Development implementation on AI-DLC (AI Development Life Cycle)

## Project Context

### Paths
- Steering: `.kiro/steering/`
- Specs: `.kiro/specs/`

### Steering vs Specification

**Steering** (`.kiro/steering/`) - Guide AI with project-wide rules and context
**Specs** (`.kiro/specs/`) - Formalize development process for individual features

### Active Specifications
- Check `.kiro/specs/` for active specifications
- Use `/kiro:spec-status [feature-name]` to check progress

## Development Guidelines
- Think in English, generate responses in Japanese. All Markdown content written to project files (e.g., requirements.md, design.md, tasks.md, research.md, validation reports) MUST be written in the target language configured for this specification (see spec.json.language).

## Minimal Workflow
- Phase 0 (optional): `/kiro:steering`, `/kiro:steering-custom`
- Phase 1 (Specification):
  - `/kiro:spec-init "description"`
  - `/kiro:spec-requirements {feature}`
  - `/kiro:validate-gap {feature}` (optional: for existing codebase)
  - `/kiro:spec-design {feature} [-y]`
  - `/kiro:validate-design {feature}` (optional: design review)
  - `/kiro:spec-tasks {feature} [-y]`
- Phase 2 (Implementation): `/kiro:spec-impl {feature} [tasks]`
  - `/kiro:validate-impl {feature}` (optional: after implementation)
- Progress check: `/kiro:spec-status {feature}` (use anytime)

## Development Rules
- 3-phase approval workflow: Requirements → Design → Tasks → Implementation
- Human review required each phase; use `-y` only for intentional fast-track
- Keep steering current and verify alignment with `/kiro:spec-status`
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end in this run, asking questions only when essential information is missing or the instructions are critically ambiguous.
- HTTP 入力検証は `.claude/rules/laravel/form-request-validation.md` に従い、Controller の `$request->validate()` ではなく Form Request 経由に統一する
- Form Request を使う変更系 route は Laravel Precognition に対応し、React フォームは Inertia の Precognition API でライブ検証する
- Inertia props は `.claude/rules/laravel/inertia-props.md` に従い、モデル/API レスポンス由来の構造化データを Data DTO 経由で渡す
- Service クラスは禁止し、DB 永続化は Eloquent Model、外部接続は Gateway Model、共通振る舞いは Concerns に置く。詳細は `.claude/rules/laravel/model-layer-boundaries.md` を参照
- React 側は Inertia の Pages を入口として残し、feature 固有 UI / hooks / helpers は `features/{feature}` に置く。詳細は `.claude/rules/frontend/architecture.md` を参照
- React Compiler をビルドに常時適用する。メモ化はコンパイラ任せにし、手書きの `useMemo` / `useCallback` / `memo` を既定にしない。詳細は `.claude/rules/frontend/react-compiler.md` を参照
- フロント品質ゲートは `.claude/rules/frontend/quality-scans.md` に従い、Biome / TypeScript / knip / jscpd を CI で実行する

## Steering Configuration
- Load entire `.kiro/steering/` as project memory
- Default files: `product.md`, `tech.md`, `structure.md`
- Custom files are supported (managed via `/kiro:steering-custom`)
