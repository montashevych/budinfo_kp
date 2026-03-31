# Mini online shop — implementation plan (Rails + Docker + PostgreSQL)

Roadmap for a small e-commerce site: Ruby on Rails, development in Docker on Windows, PostgreSQL, **shop-facing copy in Ukrainian** (with optional Russian), and an admin UI for staff.

**Note:** This document is in English. Only **customer-facing content** (UI strings, pages, product text) should be in Ukrainian / Russian via I18n and the database—not this plan.

---

## 1. Why this stack

- **Ruby on Rails** — structure, conventions, server-rendered HTML (ERB + partials) instead of a heavy SPA.
- **PostgreSQL** — natural fit for Rails; products, orders, users, admin data.
- **Docker** — same Ruby/Postgres environment on Windows without painful native installs.

---

## 2. Chosen stack (decisions locked in)

| Piece | Choice | Notes |
|-------|--------|--------|
| App | Rails 7.x or 8 | Your pick when you `rails new` |
| UI | **Hotwire** (Turbo + Stimulus) + **Tailwind CSS** (`cssbundling-rails` or `tailwindcss-rails`) | Good learning path: little custom JS, modern defaults |
| Auth | **Devise** (or Rails 8 built-in auth) | Users + separating admins |
| Admin | **[Administrate](https://github.com/thoughtbot/administrate)** | Cleaner, more “Rails app” look; easy to customize dashboards |
| i18n | Rails **I18n** — `:uk` + `:ru` | See locale section below |
| Filters | Scopes + optional **Ransack** | Elasticsearch only if you outgrow SQL |

### ActiveAdmin vs Administrate (clarification)

- **ActiveAdmin is free** — open source (MIT). Some themes/plugins may be paid, but the core gem is not.
- **Administrate** is also free (MIT). It was chosen here because it tends to look cleaner and stays closer to standard Rails views—good if you want to practice Hotwire/Tailwind in the storefront and keep admin straightforward.

---

## 3. Locales: `uk` vs `ukr`, Ukrainian + Russian

- In **Rails and ISO 639-1**, the symbol for Ukrainian is **`:uk`**, not `:ukr`.  
  (`ukr` is the ISO 639-2 *bibliographic* code; frameworks and gems expect `:uk` for Ukrainian.)
- **Russian** uses **`:ru`** (standard everywhere).

**Suggested configuration:**

- `config.i18n.default_locale = :uk` — primary UI language for the shop.
- `config.i18n.available_locales = [:uk, :ru]` — optional Russian switcher (session or user preference).
- Translation files: `config/locales/uk.yml`, `config/locales/ru.yml` (+ e.g. `devise.uk.yml`, `devise.ru.yml`).

**Content:** product names/descriptions can live in the DB; either one locale column + translation tables later, or simple `uk`/`ru` fields on models for a mini shop—decide in Phase B when you model products.

---

## 4. Deferred to late development

Do **not** build these until the catalog, cart, and orders are stable:

- **Payment gateways** (Stripe, LiqPay, WayForPay, etc.) — design `Order` and statuses so you can plug payments in later.
- **Telegram bot** (notifications, order status, support) — same idea: stable order model and webhooks/jobs first; bot as an extra channel later.

---

## 5. Docker on Windows — start

1. Install **Docker Desktop** (WSL2 backend recommended).
2. **docker-compose** with:
   - `web` — Rails (built from a `Dockerfile`);
   - `db` — `postgres:16` (or 15) + named volume.
3. Workflow: `docker compose up`, inside `web` run `rails db:create db:migrate`; mount source with a bind mount for live reload.

**Important:** From inside containers, DB host is the compose service name (`db`), not `localhost`. Set `DATABASE_URL` or `config/database.yml` accordingly. Adjust `config.hosts` for your dev hostname if needed.

---

## 6. PostgreSQL — core models (first cut)

- **Category** — name, slug, optional parent.
- **Product** — title, description, price, stock, `category_id`, `active`, optional `sku`.
- **Images** — **Active Storage** (or `ProductImage` if you prefer explicit rows).
- **User** — Devise; role `customer` / `admin` (or separate `AdminUser`).
- **Address** — delivery (linked to user or guest checkout).
- **Order** — status, totals, optional user, shipping fields.
- **OrderItem** — `order_id`, `product_id`, quantity, **unit price snapshot** at purchase time.

Indexes: `products(category_id)`, `products(active)`, `orders(user_id)`, unique slugs where used.

---

## 7. Public site structure

Routes (conceptual):

- `/` — home (featured categories/products).
- `/categories` or `/c/:slug` — category listings.
- `/products/:slug` — product detail.
- `/cart`, `/checkout` — cart and checkout (v1 can be “cash on delivery” / manual confirmation—no payment yet).
- `/delivery` — delivery info (static `Page` model with slug, or a CMS-style gem).
- `/contacts` — contact form (`ContactMessage` or mailer).

**Filters:** query params (`?min_price=&max_price=&category_id=`) + model scopes—keep v1 simple.

All **visible labels and static page body copy** go through I18n (`uk` default, `ru` optional)—avoid hardcoding English in views for shopper-facing text.

---

## 8. Frontend (Hotwire + Tailwind)

1. **ERB** + **partials** (`_product_card`, `_filters`).
2. **Turbo** — partial page updates (cart line, pagination) where it helps.
3. **Stimulus** — small behaviors (quantity +/-, mobile menu, filter toggles).
4. **Tailwind** — layout, spacing, typography; use the official docs and a simple product grid as a pattern.

No requirement for React/Vue for this mini shop.

---

## 9. Admin (Administrate)

**Goals:** manage categories, products, images, orders and statuses, optionally contact messages.

- Generate Administrate dashboards for the models above.
- Protect with authentication + admin role; route under `/admin` (or similar).
- Strong params and authorization (e.g. **Pundit**) before exposing write actions.

---

## 10. Implementation phases

### Phase A — Foundation (1–3 days)

- `rails new` with PostgreSQL; Docker + compose; env-based DB config.
- I18n: default `:uk`, available `:uk`, `:ru`; locale switcher stub if you want Russian from day one.
- Base layout (header/footer/nav) with Tailwind.
- Skeleton pages: home, delivery, contacts.

### Phase B — Catalog (3–7 days)

- Categories, products, Active Storage images.
- Listings with basic filters.
- Product show page; practice Turbo/Stimulus where natural.

### Phase C — Administrate (2–5 days)

- Install **Administrate**; dashboards for categories, products, orders (read/update as needed).

### Phase D — Cart & orders (5–10+ days)

- Session- or user-based cart.
- Checkout form → `Order` + `OrderItem` with price snapshots.
- Optional: Action Mailer for order confirmations.

### Phase E — Polish

- SEO basics (`meta-tags` gem, sitemap), localized error pages (`uk` / `ru`).
- Seeds for demo data.
- Deploy when ready (Kamal, Render, Fly.io, etc.)—Docker image reuse helps.

### Phase F — Late (after core is stable)

- **Payments** — integrate provider; webhooks; order state machine.
- **Telegram bot** — notifications or lightweight admin/alerts; reuse same order/events layer.

---

## 11. Commands (inside `web` container)

- `rails g model`, `rails db:migrate`, `rails g controller`
- `rails s` or compose command for Puma
- Tests: `rails test` or RSpec

---

## 12. Pitfalls to avoid

- Do not add payment, Telegram, coupons, and multi-warehouse on day one.
- Always use **strong parameters** and proper authorization for admin routes.
- Store **price on `OrderItem`** so historical orders stay correct when product prices change.

---

## Next steps in the repo

- Pick **Rails 7 vs 8** when generating the app.
- Add `Dockerfile`, `docker-compose.yml`, and `rails new` flags (PostgreSQL, skip default JS if you add importmap vs cssbundling consistently).

**Detailed tasks, checklists, and deployment:** see [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md).
