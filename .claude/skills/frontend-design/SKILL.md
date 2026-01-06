---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when building web components, pages, or applications. Generates creative, polished code following modern design principles.
license: MIT
---

# Frontend Design Guide

This skill guides creation of distinctive, production-grade frontend interfaces using modern design principles.

**Keywords**: frontend, react, design, UI, components, inertia, tailwind

## Design Context

**Stack**: React 19 + TypeScript + Inertia.js + Tailwind CSS v4
**Design System**: Custom theme (`resources/js/design-system/theme.ts`)

## Design Thinking

Before coding, understand the context:

- **Purpose**: What problem does this interface solve?
- **User Experience**: Design should be intuitive and accessible
- **Consistency**: Follow established design patterns
- **Accessibility**: Must meet WCAG 2.1 AA standards

## Design Principles

### 1. Color System (OKLCH)

Always use design tokens:

```typescript
import { colors } from '@/design-system/theme';

// Primary colors
const primaryColor = colors.primary[500];
const background = colors.neutral[50];

// Semantic colors
const success = colors.semantic.success;
const danger = colors.semantic.danger;
```

### 2. Typography

Use the correct font for each context:

- **Plus Jakarta Sans**: Headings, titles, hero text
- **Inter**: Body text, paragraphs, UI elements
- **JetBrains Mono**: Code, technical data, numbers

```tsx
<h1 className="font-display text-4xl">Page Title</h1>
<p className="font-body text-base">Body content...</p>
<span className="font-mono text-lg">$1,234.56</span>
```

### 3. Glassmorphism Effects

Modern, layered UI with backdrop blur:

```tsx
<div className="backdrop-blur-md bg-white/70 dark:bg-neutral-900/70 rounded-2xl shadow-soft">
  {/* Card content */}
</div>
```

### 4. Spacing

Use design tokens for consistent spacing:

```typescript
import { spacing } from '@/design-system/theme';

// spacing.small = 8px
// spacing.base = 16px
// spacing.medium = 24px
// spacing.large = 32px
```

### 5. Motion & Micro-interactions

Use Framer Motion for smooth animations:

```tsx
import { motion } from 'framer-motion';

<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.4, ease: 'easeOut' }}
>
  {/* Content fades in gently */}
</motion.div>
```

## Component Hierarchy

### 1. Primitives (`components/ui/`)

Radix-based, accessible primitives:
- `button.tsx`, `input.tsx`, `dialog.tsx`, `select.tsx`

### 2. Composite Components

Brand-styled components combining primitives:
- Cards, Forms, Modals, Navigation

### 3. Feature Components

Domain-specific components:
- Data visualization
- Forms and workflows
- Dashboard widgets

## Best Practices

### DO

- Import design tokens - never hardcode colors
- Use Radix UI primitives for accessibility
- Apply `dark:` variants for dark mode support
- Use `cn()` from `@/lib/utils` for conditional classes
- Follow existing component patterns in the codebase
- Use Inertia's `router` for navigation, not `<a>` tags

### DON'T

- Hardcode hex/RGB colors (use design tokens)
- Skip accessibility (aria-labels, keyboard navigation)
- Create new UI primitives (use existing ones)
- Ignore mobile responsiveness
- Use inline styles over Tailwind classes
- Bypass the design system

## File Organization

```
resources/js/
├── components/
│   ├── ui/              # Primitives (Radix-based)
│   ├── forms/           # Form components
│   └── layout/          # Layout components
├── design-system/
│   └── theme.ts         # Design tokens
├── layouts/             # Page layouts
├── pages/               # Inertia pages
└── hooks/               # Custom React hooks
```

## Example: Card Component

```tsx
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface CardProps {
  title: string;
  description: string;
  variant?: 'default' | 'elevated';
}

export function Card({ title, description, variant = 'default' }: CardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.3 }}
      className={cn(
        'rounded-2xl p-6 backdrop-blur-md',
        'bg-white/70 dark:bg-neutral-900/70',
        'border border-neutral-200/50 dark:border-neutral-700/50',
        variant === 'elevated' && 'shadow-lg'
      )}
    >
      <h3 className="font-display text-xl font-bold mb-2">{title}</h3>
      <p className="font-body text-neutral-600 dark:text-neutral-300">
        {description}
      </p>
    </motion.div>
  );
}
```

## Quality Checklist

Before completing UI work:

- [ ] Uses design tokens (not hardcoded values)
- [ ] Accessible (keyboard nav, screen readers)
- [ ] Responsive (mobile-first)
- [ ] Dark mode supported
- [ ] Motion is smooth and purposeful
- [ ] TypeScript types are complete
- [ ] Matches existing component patterns
