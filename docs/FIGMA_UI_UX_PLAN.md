# Figma-inspired UI/UX refresh — implementation plan

This document plans a **visual and UX refresh** of the storefront (and shared chrome) while **keeping current behaviour**: same routes, Turbo/Stimulus patterns, I18n (`uk` / `ru`), accessibility, and admin as-is unless explicitly extended.

**Design references (manual review required):**

- [Figma Make — Building Materials E-commerce (Community)](https://www.figma.com/make/1YFiUGhoQuROfByVqNV2Yq/Building-Materials-E-commerce-Website--Community-?p=f&t=qfQdcQML7hmFawCP-0) — source file; inspect frames, components, auto-layout, typography, and colour styles.
- [Published prototype — figma.site](https://final-boar-45996338.figma.site/) — click-through reference for spacing, hover states, and responsive breakpoints.

The published site is **JavaScript-heavy**; automated tools often cannot capture full layout. Treat Figma + live prototype as the **source of truth** and capture tokens below before large refactors.

---

## 1. Goals and constraints

| Goal | Detail |
|------|--------|
| **Better UI/UX** | Align with the community “building materials” e-commerce look: clearer hierarchy, stronger hero/CTA, improved product and category cards, calmer forms, consistent spacing. |
| **Same functionality** | No new business flows in phase 1: catalog, filters, cart, checkout, contacts, delivery, promotions carousel, auth, admin URLs unchanged. |
| **Stack** | Tailwind CSS v4 (`app/assets/tailwind/application.css`), ERB, importmap — no new CSS framework unless justified. |
| **i18n** | All new user-visible strings via `config/locales/{uk,ru}.yml`. |
| **A11y** | Preserve semantic HTML, focus states, `aria-*` on nav/menus/carousel; contrast meets WCAG AA for text. |

**Out of scope for this plan (unless added later):** payment UI, new pages, redesign of Administrate (can be a separate phase).

---

## 2. Design intake (do this before coding)

Complete with whoever owns design (or self-audit in Figma):

1. **Colour tokens** — primary, secondary, surface, border, text primary/muted, success/warning/error; map each to Tailwind theme extensions or CSS variables in `application.css` (e.g. `@theme` / custom properties).
2. **Typography** — font families (e.g. geometric sans + optional display), sizes for H1–H6, body, captions; decide if [Google Fonts](https://fonts.google.com) or system stack; wire via `layouts/application.html.erb` + Tailwind `font-*`.
3. **Spacing & radius** — section vertical rhythm (e.g. `py-16` vs `py-10`), card radius, button radius; document “canonical” container max-width (current `max-w-5xl` may become `max-w-6xl` or full-bleed sections).
4. **Components inventory** — list Figma components: header variants, hero, category tiles, product card, filter bar, cart row, checkout steps, footer columns, empty states.
5. **Breakpoints** — note md/lg/xl behaviour from prototype; match Tailwind defaults unless Figma specifies otherwise.
6. **Assets** — optional logo mark, hero imagery style (stock vs illustration); keep existing Active Storage for products.

**Deliverable:** a short **DESIGN_TOKENS.md** snippet or comments in `application.css` listing hex + usage names so implementation stays consistent.

---

## 3. Code map (what will change)

| Area | Primary files / partials |
|------|---------------------------|
| **Global shell** | `app/views/layouts/application.html.erb`, `app/views/layouts/error.html.erb` (light touch) |
| **Header / nav** | Same layout; optional `app/views/shared/_header.html.erb` extract; `mobile_menu_controller.js` |
| **Footer** | `application.html.erb` footer block; optional `shared/_footer.html.erb` |
| **Home** | `app/views/home/index.html.erb`, `home/_promotions_carousel.html.erb`, `promotion_carousel_controller.js` |
| **Categories** | `categories/index`, `categories/show` |
| **Products** | `products/index`, `products/show`, product grid/card partials, filters UI, `_add_to_cart.html.erb` |
| **Cart** | `carts/show` |
| **Checkout** | `checkouts/new`, `order_confirmations/show` |
| **Static / forms** | `pages/delivery`, `contacts/new`, `sessions`, `registrations`, `passwords` (styling pass) |
| **Shared** | `shared/*` icons, badges, flashes (optional component classes in `@layer components`) |
| **Tailwind** | `app/assets/tailwind/application.css` — theme, utilities, Pagy overrides |

Admin (`app/views/admin/**`, Administrate) — **phase 2 optional**.

---

## 4. Implementation phases

### Phase A — Design tokens & layout foundation (1–2 days) ✅ **Done**

- Extend Tailwind theme: colours, fonts, radii, shadows, container width.
- Add global base styles if needed (`@layer base` for `body`, links, focus rings).
- Define reusable **component classes** in `@layer components` (e.g. `.btn-primary`, `.btn-secondary`, `.card`, `.section-title`) to avoid duplicating long class strings in ERB.
- Run `bin/rails tailwindcss:build` (or Docker equivalent) after changes.

**Exit criteria:** One demo page (e.g. home) can use new tokens without regressing contrast or LCP on hero image.

**Implemented:** `@theme` + `@layer base` in `app/assets/tailwind/application.css`; **Plus Jakarta Sans** (Google Fonts) in `application` + `error` layouts; semantic utilities (`bg-surface-page`, `text-ink`, `bg-brand`, …); components `.btn-primary`, `.btn-secondary`, `.section-title`, `.section-intro`, `.card`; Pagy nav aligned to tokens; home hero uses new section + buttons; shell (header/footer/main width `max-w-6xl`) aligned to tokens so Phase B can focus on structure. Reference: **`docs/DESIGN_TOKENS.md`**.

**Pause:** Next session → **Phase B** (shell polish: logo treatment, nav hierarchy, footer columns, full-bleed sections if needed).

### Phase B — Shell: header, footer, main width (1–2 days) ✅ **Done**

- Rebuild header: logo area, primary nav, cart CTA (prominent), locale, auth — match Figma hierarchy; keep all existing links and Turbo behaviour.
- Footer: multi-column links (delivery, contacts, catalog, products), copyright, optional short tagline.
- Decide **full-bleed vs boxed** sections; use `w-full` sections with inner `mx-auto max-w-*` where the design shows edge-to-edge backgrounds.

**Exit criteria:** Keyboard nav + mobile menu work; cart badge updates unchanged.

**Implemented:** `app/views/shared/_header.html.erb` — sticky bar (`backdrop-blur`), brand + `layouts.application.tagline`, centered desktop nav with `.nav-link` / `.nav-link-active`, locale + auth + **`.nav-cart-cta`** cart button; mobile **brand-filled** cart chip + menu. `app/views/shared/_footer.html.erb` — four-column grid (brand blurb, shop, customers, account), bottom bar with copyright + `layouts.footer.rights`. New I18n under `layouts.application.tagline` and `layouts.footer.*` (`uk` / `ru`). Component classes in `application.css`: `.nav-link`, `.nav-cart-cta`, `.footer-heading`, `.footer-link`. `application.html.erb` renders partials; cart toast `top` offset adjusted for sticky header.

**Pause:** Next → **Phase C** (home hero refinement + promotions carousel styling).

### Phase C — Home & promotions (1–2 days)

- Hero block: headline, intro, dual CTAs (catalog / products), optional background or gradient per design.
- Tune promotions carousel: typography on overlay bar, arrow/button styling, dots, autoplay timing if specified.
- Ensure `home-promo-media-box` still works; adjust min-heights only if design requires.

**Exit criteria:** Meta tags and carousel links unchanged; Stimulus controller behaviour preserved.

### Phase D — Catalog: categories & product listing (2–3 days)

- **Category index/show:** card grid or list styling consistent with Figma product tiles.
- **Products index:** filter strip (category, price) — clearer labels, mobile collapse or horizontal scroll if needed; Pagy styled to match.
- **Product cards:** image ratio, price emphasis, stock badge, add-to-cart affordance (still Turbo where applicable).

**Exit criteria:** Turbo frame `products` and filters still work; inactive products still hidden.

### Phase E — Product detail & cart (1–2 days)

- Gallery layout, title/price hierarchy, SKU, description typography.
- `_add_to_cart`: primary button style, stepper styling, disabled/out-of-stock states.
- **Cart page:** line items as clear rows, totals, checkout CTA prominence, empty state illustration or message.

**Exit criteria:** All cart Turbo Stream responses still render correct partials/IDs.

### Phase F — Checkout & confirmation (1 day)

- Form layout: grouped fields, validation error placement, submit button.
- Order confirmation: success visual hierarchy, “continue shopping” CTA.

**Exit criteria:** Same controller params and mailer behaviour.

### Phase G — Contacts, delivery, auth screens (1–2 days)

- Unify form controls (input height, labels, errors) with catalog/checkout.
- Session/registration/password pages: card layout, trust copy if in design.

### Phase H — Polish & QA (1–2 days)

- Focus-visible rings on all interactive elements.
- Reduced motion: respect `prefers-reduced-motion` for carousel/animations.
- Cross-browser smoke (Chrome, Safari, Firefox); mobile widths 360–430px.
- Run **`bin/docker-test`**; fix any system test selectors if markup changes (e.g. `form[action=...]`).

---

## 5. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Figma ≠ feasible in ERB | Prioritise **layout and tokens** over pixel-perfect clones; document intentional deltas. |
| Tailwind class explosion | Extract `components` layer and small partials (`shared/_button_primary.html.erb` optional). |
| Turbo breakages | Change classes only where possible; preserve `dom_id`, `data-turbo-stream`, frame IDs. |
| Performance | Avoid huge inline SVGs; lazy-load below-fold images; keep font subsets small. |

---

## 6. Definition of done (MVP refresh)

- [ ] Tokens documented and applied consistently.
- [ ] Header, footer, home, catalog, product, cart, checkout match the agreed Figma **structure** (spacing, type scale, colour roles).
- [ ] No regression in core flows (browse → add to cart → checkout → confirmation).
- [ ] Locales updated for any new copy; no hardcoded Ukrainian/Russian in new chrome.
- [ ] Tests green (`bin/docker-test`).

---

## 7. After MVP

- Administrate skin or separate admin layout (low priority for shoppers).
- Dark mode — only if Figma includes it.
- Optional: Storybook-style static component page in dev (not required for v1).

---

## Cross-references

- Deploy and ops: [DEVELOPMENT_PLAN.md](../DEVELOPMENT_PLAN.md) — Deployment, Current readiness.
- Promotions feature details: [HOME_PROMOTIONS_PLAN.md](./HOME_PROMOTIONS_PLAN.md).
