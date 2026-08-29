---
name: brand-guidelines
description: Design system guidelines for brand colors, typography, and styling. Use when brand colors, style guidelines, visual formatting, or design standards apply.
license: MIT
---

# Design System Guidelines

## Overview

This project uses a modern design system combining accessibility with cutting-edge UI/UX. The system emphasizes perceptual uniformity and consistent visual language.

**Keywords**: branding, design-system, colors, typography, visual-identity, UI, styling

## Design Philosophy

- **Consistent spacing** using design tokens
- **Modern color system** using OKLCH color space for perceptual uniformity
- **Accessible design** with proper contrast ratios
- **Responsive typography** using fluid sizing

## Brand Colors

### Primary Palette

```typescript
primary: {
  50:  'oklch(97% 0.02 250)',  // Lightest
  100: 'oklch(94% 0.04 250)',
  200: 'oklch(88% 0.08 250)',
  300: 'oklch(78% 0.12 250)',
  400: 'oklch(68% 0.16 250)',
  500: 'oklch(58% 0.20 250)',  // Main
  600: 'oklch(50% 0.18 250)',
  700: 'oklch(42% 0.16 250)',
  800: 'oklch(34% 0.14 250)',
  900: 'oklch(26% 0.12 250)',
  950: 'oklch(18% 0.10 250)',  // Darkest
}
```

### Semantic Colors

```typescript
semantic: {
  success: 'oklch(70% 0.25 145)',   // Confirmation, positive
  warning: 'oklch(75% 0.22 75)',    // Caution, attention needed
  danger:  'oklch(65% 0.28 25)',    // Errors, risks, alerts
  info:    'oklch(68% 0.22 220)',   // Information, guidance
}
```

### Neutral Palette

Grayscale for backgrounds and text:

```typescript
neutral: {
  0:   'oklch(100% 0 0)',      // Pure white
  50:  'oklch(98% 0.005 250)', // Slight tint
  100: 'oklch(96% 0.005 250)',
  200: 'oklch(90% 0.005 250)',
  300: 'oklch(80% 0.005 250)',
  400: 'oklch(70% 0.005 250)',
  500: 'oklch(55% 0.005 250)', // Mid gray
  600: 'oklch(45% 0.005 250)',
  700: 'oklch(35% 0.005 250)',
  800: 'oklch(25% 0.005 250)',
  900: 'oklch(15% 0.005 250)',
  950: 'oklch(8% 0.005 250)',  // Near black
}
```

## Typography

### Font Families

```typescript
fontFamily: {
  display: '"Plus Jakarta Sans Variable", -apple-system, sans-serif',
  body: '"Inter Variable", -apple-system, sans-serif',
  mono: '"JetBrains Mono Variable", monospace',
}
```

### Usage Guidelines

- **Display font**: Headings, titles, hero sections
- **Body font**: All body text, paragraphs, lists
- **Mono font**: Code, technical data, numbers

### Fluid Font Sizes

Uses `clamp()` for responsive sizing:

```typescript
fontSize: {
  xs:   'clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem)',
  sm:   'clamp(0.875rem, 0.8rem + 0.375vw, 1rem)',
  base: 'clamp(1rem, 0.9rem + 0.5vw, 1.125rem)',
  lg:   'clamp(1.125rem, 1rem + 0.625vw, 1.25rem)',
  xl:   'clamp(1.25rem, 1.1rem + 0.75vw, 1.5rem)',
  '2xl': 'clamp(1.5rem, 1.3rem + 1vw, 1.875rem)',
  '3xl': 'clamp(1.875rem, 1.5rem + 1.875vw, 2.5rem)',
  '4xl': 'clamp(2.25rem, 1.8rem + 2.25vw, 3rem)',
}
```

## Spacing System

Consistent spacing tokens:

```typescript
spacing: {
  xs:     '4px',
  small:  '8px',
  base:   '16px',
  medium: '24px',
  large:  '32px',
  xl:     '48px',
  '2xl':  '64px',
}
```

## Component Usage

### Accessing Design Tokens

Tailwind CSS v4 は CSS-first 設定。token は `resources/css/app.css` の `@theme` に定義し、
コンポーネントからは Tailwind utility として参照する。TypeScript の theme オブジェクトは持たない。

```css
/* resources/css/app.css */
@theme {
    --color-primary-500: oklch(58% 0.2 250);
    --color-primary-600: oklch(50% 0.18 250);
    --color-success: oklch(70% 0.25 145);

    --spacing-medium: 24px;
}
```

```tsx
<div className="bg-primary-500 p-medium text-white">
    <span className="text-success">保存しました</span>
</div>
```

JS 側から値そのものが必要になった場合だけ `getComputedStyle(document.documentElement)`
で CSS variable を読む。token を TypeScript 側に二重定義しない。

### Effects & Glassmorphism

```typescript
effects: {
  glass: {
    light: 'backdrop-blur-sm bg-white/70',
    medium: 'backdrop-blur-md bg-white/50',
    dark: 'backdrop-blur-lg bg-neutral-900/70',
  },
  shadows: {
    soft: '0 2px 15px -3px rgb(0 0 0 / 0.07)',
    medium: '0 10px 40px -10px rgb(0 0 0 / 0.15)',
    strong: '0 20px 50px -15px rgb(0 0 0 / 0.25)',
  },
  radius: {
    sm: '4px',
    md: '8px',
    lg: '12px',
    xl: '16px',
    '2xl': '24px',
    full: '9999px',
  }
}
```

## Best Practices

### DO

- Use design tokens instead of hardcoded values
- Apply glassmorphism effects for modern, layered UI
- Use fluid typography for responsive text
- Maintain consistent spacing using tokens
- Support dark mode with `dark:` variants

### DON'T

- Hardcode hex values (use OKLCH tokens)
- Use hard shadows (prefer soft, layered shadows)
- Override design tokens without good reason
- Ignore dark mode support
- Use non-variable fonts when possible

## File Locations

- **Theme / Design Tokens**: `resources/css/app.css` の `@theme` block
- **汎用 UI Components**: `resources/js/shared/components/`
- **feature 固有 UI**: `resources/js/features/{feature}/components/`

配置の正本は `.ai/rules/frontend/architecture.md`。

## Dark Mode

All colors support dark mode via Tailwind's `dark:` prefix:

```tsx
<div className="bg-neutral-50 dark:bg-neutral-900 text-neutral-900 dark:text-neutral-50">
  {/* Content adapts to theme */}
</div>
```

## Tailwind CSS v4 Integration

Use CSS variables for design tokens:

```css
@theme {
  --color-primary-500: oklch(58% 0.20 250);
  --color-neutral-50: oklch(98% 0.005 250);
  --font-family-display: 'Plus Jakarta Sans Variable', system-ui, sans-serif;
  --spacing-base: 16px;
}
```

## References

- [OKLCH Color Space](https://oklch.com/)
- [Tailwind CSS v4](https://tailwindcss.com/docs)
- [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans)
- [Inter Variable](https://fonts.google.com/specimen/Inter)
