# Design tokens (Phase A — Figma UI refresh)

Canonical definitions live in **`app/assets/tailwind/application.css`** inside `@theme { … }`. Update both places when the Figma file exports new values.

## Typography

| Token | Usage |
|-------|--------|
| **Sans** | `Plus Jakarta Sans` (Google Fonts) → `--font-sans` → `font-sans` |

## Colours (semantic)

| Role | Tailwind utility | Notes |
|------|------------------|--------|
| Page background | `bg-surface-page` | Warm neutral |
| Cards / header | `bg-surface-card` | White |
| Muted blocks | `bg-surface-muted` | Subtle panels |
| Primary text | `text-ink` | Body, headings |
| Secondary text | `text-ink-muted` | Nav, captions |
| Tertiary | `text-ink-subtle` | Hints |
| Brand / CTA | `bg-brand`, `text-brand` | Orange — adjust hex in `@theme` to match Figma |
| Brand hover | `bg-brand-hover` | Darker for buttons |
| On brand | `text-on-brand` | Button label |
| Borders | `border-border`, `border-border-strong` | |

## Radius & shadow

| Token | Utility |
|-------|---------|
| `--radius-sm` … `--radius-xl` | `rounded-sm` … `rounded-xl` (if mapped) |
| `--shadow-card` | `shadow-card` |
| `--shadow-card-hover` | `shadow-card-hover` |

## Components (CSS classes)

Defined in `@layer components` in `application.css`:

- `.btn-primary` — solid CTA
- `.btn-secondary` — outline CTA
- `.section-title` — page hero H1
- `.section-intro` — supporting copy under hero
- `.card` — elevated surface
- **Phase B — shell:** `.nav-link`, `.nav-link-active`, `.nav-cart-cta`, `.footer-heading`, `.footer-link`

See **`docs/FIGMA_UI_UX_PLAN.md`** for phased rollout (Phase C+).
