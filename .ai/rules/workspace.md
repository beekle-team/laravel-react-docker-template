# Workspace Rules

## Communication

- 内部では英語で考え、ユーザーへの応答とプロジェクト文書は日本語で書く。
- 既存実装、既存ルール、ユーザー変更を尊重する。

## Laravel

- Form Request / Precognition
- Inertia props は Data DTO
- Service class 禁止、Eloquent / Gateway / Concerns の境界
- 詳細は .claude/rules/laravel/ と .claude/rules/php.md

## React

- Pages を Inertia entry として維持
- feature 固有実装は features/{feature}/
- 2箇所以上の共有物だけ shared/
- React Compiler 常時適用

## Quality Gates

- PHP: Pint、PHPStan、Rector dry-run、Pest
- Frontend: Biome、TypeScript、React Compiler、knip、jscpd、Vitest
- User flow: Playwright
- Testing は .ai/rules/testing.md
- 異常系は .ai/rules/error-handling.md
