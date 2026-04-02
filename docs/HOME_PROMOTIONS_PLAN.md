# Home promotions (hero carousel) — implementation plan

**Status:** Phases 1–2 implemented. Phases 3+ pending.

**Goal:** A storefront-style promotional area on the home page: admin-managed slides (image + short text), auto-rotating carousel (10s), manual prev/next, and a dedicated detail page per slide (large image + long text). Admins customize content from the existing admin panel.

---

## Principles

- **Sliced delivery:** Each phase is a coherent increment; merge and deploy independently where possible.
- **Reuse stack:** PostgreSQL, Active Storage (already used for products), Administrate, Stimulus, Turbo, existing i18n (`uk` / `ru`).
- **No scope creep in Phase 1:** Scheduling, A/B tests, analytics, and swipe gestures are explicitly out of scope unless listed under “Later”.

---

## Phase 1 — Data model & Active Storage ✅

**Objective:** Persist promotional slides in the database with one image per slide.

**Done:** `HomePromotion` model, `db/migrate/20260403120000_create_home_promotions.rb`, `test/models/home_promotion_test.rb`, i18n (`uk` / `ru`).

**Tasks**

1. Add model, e.g. `HomePromotion` (name TBD in implementation), with at least:
   - `title` (string) — short headline for carousel overlay / caption.
   - `teaser` or `subtitle` (text, optional) — one–two lines under title on carousel.
   - `slug` (string, unique) — URL segment for the public detail page.
   - `body` (text or `rich text`) — long copy for the detail page (see Phase 2). If you prefer WYSIWYG later, plan for `action_text_rich_text` now or migrate in a follow-up slice.
   - `position` (integer) — sort order on home.
   - `active` (boolean) — hide without deleting.
   - `timestamps`
2. Attach **one** `has_one_attached :image` (same patterns as `Product`: validations for type/size if desired).
3. Migration + model validations (presence: title, slug, image for active records; slug format).
4. **Locales:** only if model error messages need new keys; keep minimal.

**Definition of done**

- `rails db:migrate` succeeds; model can be created in console with image.

**Depends on:** Nothing.

---

## Phase 2 — Public detail page (“promotion page”) ✅

**Objective:** Clicking carousel image or text opens a full page: image on top, then structured content (title + body).

**Done:** `PromotionsController#show`, `GET /promotions/:slug`, `app/views/promotions/show.html.erb`, `test/controllers/promotions_controller_test.rb`.

**Tasks**

1. Route, e.g. `GET /promotions/:slug` → `PromotionsController#show` (or `HomePromotionsController#show`).
2. Load record by `slug`, only **`active`**; otherwise `404`.
3. View: hero image (full width or constrained max width to match site), then heading, then body (HTML-safe rendering if plain text with `simple_format`, or rich text when added).
4. SEO: set `meta` title/description from promotion fields (reuse existing `meta-tags` pattern).
5. Optional: link “Back to home” in footer of block.

**Definition of done**

- Direct URL works; inactive slug returns 404; layout matches storefront.

**Depends on:** Phase 1.

---

## Phase 3 — Administrate CRUD

**Objective:** Admins create/edit/reorder promotions without code deploys.

**Tasks**

1. Add `Administrate` dashboard for `HomePromotion` (or chosen model name): index, show, new, edit, destroy.
2. Form fields: title, teaser, slug (with hint: URL fragment), body, position, active, image upload (Administrate + Active Storage field already in project).
3. Optional: default slug from title on create (server-side); admin can override.
4. Restrict to **admin users** only (same as other admin resources).

**Definition of done**

- Admin can CRUD and reorder; image appears on show; inactive slides hidden from public index query.

**Depends on:** Phase 1.

---

## Phase 4 — Home page integration (data + markup)

**Objective:** Home renders a promotion area driven by DB.

**Tasks**

1. `HomeController#index`: load `HomePromotion.active.ordered` (scope on model).
2. Partial, e.g. `home/_promotions_carousel.html.erb`, rendered only if any slides exist (empty state = no block, no broken layout).
3. Each slide: image, title, teaser, link wrapping image and/or text to detail URL (`promotion_path(slug)`).
4. Pass slide count and URLs into a **Stimulus** controller (Phase 5).

**Definition of done**

- With 2+ active slides, home shows them stacked or in a single container ready for JS; links go to detail pages.

**Depends on:** Phases 1–3 (3 needed so admins can populate data; can mock seeds for dev-only testing before 3 if desired).

---

## Phase 5 — Carousel behavior (Stimulus)

**Objective:** Famous-shop-style rotation: 10s auto-advance, arrows, accessible controls.

**Tasks**

1. Stimulus controller, e.g. `promotion_carousel`:
   - Shows one slide at a time (CSS: hide others or single visible panel).
   - **Autoplay:** `setInterval` 10s, advance to next; loop to first after last.
   - **Prev / Next** buttons: decrement/increment index, reset timer (recommended so manual navigation doesn’t immediately fire autoplay).
   - **Pause** on hover or focus within carousel (optional but recommended for a11y).
   - **Click** on slide image/text: navigate to detail page (native `<a>` or `data-turbo="false"` if needed — prefer real links for SEO and middle-click).
2. Keyboard: focusable prev/next; optional arrow keys when carousel focused.
3. `aria-live="polite"` or `role="region"` + `aria-roledescription="carousel"` + labelledby for screen readers.

**Definition of done**

- Auto-rotate ~10s; arrows work; no duplicate navigations; basic a11y pass.

**Depends on:** Phase 4.

---

## Phase 6 — Tests, seeds, documentation

**Objective:** Regression safety and onboarding.

**Tasks**

1. Model tests: validations, scopes (`active`, `ordered`).
2. Request/controller tests: `show` active vs inactive; home includes carousel when slides exist.
3. Optional system test: carousel DOM + one manual advance (if CI allows).
4. `db/seeds.rb` or README snippet: 1–2 sample promotions for local demo (optional images or placeholders).
5. Short note in `README` or `DEVELOPMENT_PLAN.md`: how admins manage promotions.

**Definition of done**

- CI green; new contributor can enable demo content.

**Depends on:** Phases 1–5.

---

## Naming & URLs (proposal)

| Item | Proposal |
|------|-----------|
| Model | `HomePromotion` |
| Public detail path | `/promotions/:slug` |
| Admin | `/admin/home_promotions` |

(Adjust names in implementation if you prefer Ukrainian routes or a single `promo` prefix.)

---

## Explicitly out of scope (for later)

- Date-based scheduling (start/end dates).
- Per-locale different images (unless you ask — would be Phase 7+).
- Video backgrounds, parallax, swipe-only mobile UX.
- Analytics / impression tracking.
- Multiple images per promotion (gallery).

---

## Suggested order of execution

1 → 2 → 3 → 4 → 5 → 6  

Phases 2 and 3 can be **swapped** (admin before detail page) if you want to enter content before testing public URLs.

---

## Approval checklist

Please confirm or adjust:

- [ ] Model name and URL path (`/promotions/:slug` OK?)
- [ ] Body field: **plain text** (`simple_format`) for v1, or **Action Text** rich text from the start?
- [ ] Carousel: **pause on hover/focus** — yes/no?
- [ ] Maximum number of simultaneous active slides (unlimited vs soft cap)?

After you approve this document (and answer the checklist if needed), implementation will follow these phases in order.
