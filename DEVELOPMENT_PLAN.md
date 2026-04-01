# Detailed development & deployment plan

This document expands [PLAN.md](./PLAN.md) into **actionable tasks**, **checklists**, and a **deployment** path. Use it as a day-by-day guide; adjust estimates to your pace.

---

## How to use this document

1. Work **phases in order** (A → F). Later phases assume earlier ones exist.
2. Check off **Definition of done** items before moving on.
3. Run **`bin/docker-test`** (or `bin/docker-rails test …`) after each vertical slice when you add tests.
4. All **shop-facing strings** use I18n (`:uk` default, `:ru` optional)—see PLAN.md §3.

---

## Prerequisites

| Item | Action |
|------|--------|
| Docker Desktop | Installed; WSL2 backend enabled (Windows) |
| Git | Repo initialized when the Rails app exists |
| Editor | Cursor / VS Code with Ruby + Docker extensions (optional) |
| Accounts (for deploy) | Chosen host (Render / Fly / VPS / etc.) + domain DNS access |

---

## Phase 0 — Project bootstrap

**Phase 0 — status:** Successfully passed for this repository (Docker-first path: Rails 8, PostgreSQL 16, Tailwind + Hotwire, Compose services `web` / `db` / `pgadmin`, `Dockerfile.dev` for dev and generated `Dockerfile` for production/Kamal). Use the host port published in `docker-compose.yml` for the app (e.g. `http://localhost:3001` if `3001:3000` is set).

### 0.1 Create the Rails application

**Options (pick one path and stay consistent):**

- **Path A — Docker-first:** Minimal `Dockerfile` + `docker-compose.yml`, then `rails new` *inside* the `web` container into a mounted folder, OR generate on host and copy in—whichever your template uses.
- **Path B — Generate locally, then Dockerize:** `rails new simple_shop --database=postgresql` then add Docker.

**Suggested `rails new` flags (conceptual):**

- Database: **postgresql**
- For Tailwind + JS bundling: add **cssbundling-rails** with Tailwind (or `tailwindcss-rails` per current Rails docs for your version).
- Keep **importmap** OR use **jsbundling** with esbuild if you want a single pipeline with Tailwind; avoid mixing three JS systems.

**Deliverables:**

- [x] `Gemfile` includes `pg`, Hotwire defaults (`turbo-rails`, `stimulus-rails`), Tailwind setup per chosen gem.
- [x] `config/database.yml` uses `ENV['DATABASE_URL']` or host `db` for Docker.
- [x] `.env.example` lists `DATABASE_URL`, `RAILS_MASTER_KEY`, `SECRET_KEY_BASE` (for production), `RAILS_ENV`.

### 0.2 Docker Compose (development)

**Services:**

| Service | Image / build | Ports | Notes |
|---------|---------------|-------|--------|
| `db` | `postgres:16-alpine` | 5432 internal | Volume `postgres_data`; env `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` |
| `web` | Build from `Dockerfile` | `3000:3000` | Depends on `db`; `bundle install`; mount `.:/app` |

**`web` container typical env:**

- `DATABASE_URL=postgres://USER:PASS@db:5432/DBNAME`
- `RAILS_ENV=development`

**Deliverables:**

- [x] `docker compose up` starts DB + web.
- [x] `docker compose run web rails db:create` succeeds.
- [x] Browser opens app at the mapped host URL (see `docker-compose.yml`; e.g. `http://localhost:3001`).

**Run Rails/DB tasks inside Compose (preferred on this project):** use one-off `web` containers so gems and Postgres match production-like dev.

- Migrations: `bin/docker-rails db:migrate`
- Seed: `bin/docker-rails db:seed`
- Tests: `bin/docker-test-prepare` once (or after schema changes), then **`bin/docker-test`**.  
  (Wrapper sets `RAILS_ENV=test` and `DATABASE_URL` for `app_test`; override with **`DOCKER_TEST_DATABASE_URL`** if needed.)

### 0.3 Git hygiene

- [x] `.gitignore` includes `/log`, `/tmp`, `/storage`, `.env`, `master.key` handling per Rails docs.
- [x] `config/master.key` **not** committed; use `RAILS_MASTER_KEY` in production.

**Phase 0 definition of done:** App boots in Docker; DB connects; Tailwind builds; Hotwire loads on a smoke page. **Done for this repo.**

---

## Phase A — Foundation

**Phase A — status:** A.1–A.3 done: I18n (`uk` / `ru`), layout shell, **Rails 8 native authentication** (`bin/rails generate authentication`), `User` roles `customer` / `admin`, localized auth views, seeds admin (`db/seeds.rb`, optional `ADMIN_SEED_PASSWORD`).

### A.1 Internationalization

**Tasks:**

1. Set in `config/application.rb` (or initializer):

   - `config.i18n.default_locale = :uk`
   - `config.i18n.available_locales = [:uk, :ru]`
   - `config.i18n.fallbacks = [:en]` *only if* you keep English keys as fallback (optional).

2. Create `config/locales/uk.yml`, `config/locales/ru.yml` with at least:

   - `layouts.application` title, nav labels (home, catalog, delivery, contacts, cart).
   - Flash / error scaffolding.

3. Add **locale switcher** (session or query param `?locale=ru`): `before_action` in `ApplicationController` to set `I18n.locale`.

4. Optional: route scope `scope "(:locale)", locale: /uk|ru/` if you want `/ru/...` URLs—otherwise session is enough for v1.

**Checklist:**

- [x] No Ukrainian/Russian shopper copy hardcoded in English in main layout.
- [x] Switching locale updates nav and shared strings.

### A.2 Base layout & static skeleton

**Tasks:**

1. `layouts/application.html.erb` — semantic structure (`header`, `main`, `footer`), Tailwind container, responsive nav.
2. Stimulus controller for **mobile menu** (optional but good practice).
3. Controllers + empty actions:

   - `HomeController#index`
   - `PagesController` or `StaticController` for delivery copy (or placeholder until `Page` model exists).
   - `ContactsController#new` + `#create` stub.

4. Routes in `config/routes.rb` — root, `delivery`, `contacts`.

**Checklist:**

- [x] Root renders with Tailwind styling.
- [x] Footer has placeholder links (policy pages can wait until Phase E).

### A.3 Authentication (Rails 8 native — chosen)

**Why native instead of Devise (shop + admins):**

| Topic | Rails 8 `generate authentication` | Devise |
|-------|-------------------------------------|--------|
| Footprint | Small: `User`, `Session`, cookie, `Authentication` concern — matches app code | Larger DSL, more generators, more “magic” |
| Upgrades | Stays aligned with Rails releases | Extra gem compatibility work per Rails major |
| Admin (`/admin`) | Same `User` + `current_user.admin?` + `before_action` in `Admin::ApplicationController` | `authenticate_user!` + role check — same idea, different API |
| Customization | You own every line (password reset mail, rate limits already in generated controllers) | Often `devise_scope`, overridden controllers, I18n YAML for devise views |
| Features | Covers sign-in, session cookie, password reset; **registration** added as `RegistrationsController` | Registration, confirmable, lockable, OAuth plugins, etc. out of the box |

**Product rules tracked here:**

- **Guest checkout:** placing an order must **not** require registration. Phase **D** `OrdersController` / checkout flow will use `allow_unauthenticated_access` (and optional `user_id` when logged in). Registered users are optional.
- **Cart persistence (30 days):** guest cart should survive return visits ~**30 days** — implement in Phase **D** with **`Rails.cache`** (or Solid Cache) keyed by signed cookie / `guest_cart_id`, `expires_in: 30.days`, not only the default session cookie. Documented under Phase D.1 below.

**Implemented tasks:**

1. `bin/rails generate authentication` + `bcrypt`; migration **`role`** on `users` (`enum`: `customer`, `admin`).
2. **`RegistrationsController`** — public sign-up always creates **`customer`** (never `admin` from params).
3. **`db/seeds.rb`** — `admin@example.com` (password from `ADMIN_SEED_PASSWORD` or dev default; change in production).
4. I18n for sessions, registration, passwords, mailer (`uk` / `ru`); layout links **Увійти / Реєстрація / Вийти**.
5. Public controllers use **`allow_unauthenticated_access`** so the storefront stays open without login.

**Checklist:**

- [x] Sign up / sign in / sign out + password reset flow; strings in `:uk` / `:ru`.
- [x] `current_user` / `authenticated?` available in views (via `Authentication`).

**Phase A definition of done:** Localized shell of the site; auth works; Docker workflow is routine. **Met for A.1–A.3.**

---

## Phase B — Catalog

### B.1 Categories

**Admin:** Categories (and later products) are intended to be **created and edited by staff in `/admin`** once **Phase C (Administrate)** is installed. Until then, use **`db/seeds.rb`** or Rails console. Demo seeds describe a **building materials** shop (сухі суміші, утеплення, пиломатеріали, інструмент).

**Migration sketch:**

- `categories`: `name_uk`, `name_ru` (or single `name` + JSON/translations later), `slug` (unique, indexed), `parent_id` (optional, self-referential).

**Tasks:**

1. `rails g model Category ...`
2. Model: `friendly_id` or manual slug validation; `has_many :products`.
3. Controller: `CategoriesController#index`, `#show` (by slug).
4. Views: list + show with product grid partial.

**Checklist:**

- [x] Slugs are unique; invalid slugs 404.

### B.2 Products

**Migration sketch:**

- `products`: `title_uk`, `title_ru`, `description_uk`, `description_ru` (or your chosen i18n strategy), `price` (decimal, precision 10, scale 2), `stock` (integer), `active` (boolean), `sku` (optional, unique), `category_id`, `slug` (unique).

**Tasks:**

1. `rails g model Product ...`
2. **Active Storage**: `has_many_attached :images` on `Product`; validations (content type, size).
3. Scopes: `active`, `in_stock`, `by_category(slug)`.
4. `ProductsController#index` (filters: `category_id`, `min_price`, `max_price` via strong params).
5. `ProductsController#show` — Turbo-friendly gallery optional.

**Checklist:**

- [x] Filters cannot inject SQL (use bound parameters / scopes only).
- [x] Inactive products not listed; direct slug access returns 404 or “unavailable” per your policy.

### B.3 Turbo / Stimulus touches

- [x] Pagination: `turbo_frame` or full page—pick one and stay consistent. (**Implemented:** Pagy `:offset` + `<turbo-frame id="products">` for grid, filters, and page links; full document load without frame header; `data-turbo-action="advance"` on the frame for URL updates.)
- [x] “Add to cart” on product cards and show page posts to **`CartsController#add`** (Phase D.1).

**Phase B definition of done:** Full browse path: categories → filtered list → product detail with images; copy in Ukrainian/Russian per DB fields + I18n chrome.

---

## Phase C — Administrate

### C.1 Install & namespace

**Tasks:**

1. Add `administrate` gem; run install generator.
2. Mount dashboards under `/admin`.
3. **Authenticate**: `before_action` requiring `current_user.admin?` (same `User` model as storefront; no Devise).
4. Consider **Pundit** for `Admin::ApplicationController` policies if you split permissions later.

**Implemented (C.1):**

- Gem `administrate ~> 1.0` (Rails 8–compatible); dashboards generated for `Category`, `Product`, `User`.
- Routes: `namespace :admin` → `/admin`, `root` → categories index; **no** `Session` admin resource.
- `Admin::ApplicationController` includes **`Authentication`** (must sign in) and **`require_admin`** → `current_user.admin?` or redirect to root with `t("admin.forbidden")`.
- Storefront nav shows **Адмін** link when `current_user.admin?`.
- **Pundit:** not added; revisit when splitting admin roles.

### C.2 Dashboards

Register resources:

- [x] `Category`
- [x] `Product` — **`administrate-field-active_storage`** for `has_many_attached :images`; uploads handled in **`Admin::ProductsController`** (stash + attach after save — see *Operational notes — Product images & Active Storage*); `scoped_resource` uses `with_attached_images`.
- [x] `User` (no `password_digest` / sessions in UI; `password` + `password_confirmation` optional on edit via `Admin::UsersController#resource_params`)
- [x] `Order`, `OrderItem` — models + migration; **`OrderDashboard`** / **`OrderItemDashboard`**; **`Admin::OrdersController`** / **`Admin::OrderItemsController`** (`scoped_resource` orders by `created_at` desc); routes `resources :orders`, `resources :order_items`. Storefront checkout/cart still **Phase D**.

**Checklist:**

- [x] Non-admin users get 403/redirect from `/admin`. (Guests → sign-in; customers → root + flash.)
- [x] Strong params in Administrate overrides match your model attributes. (`Admin::UsersController`, `ProductDashboard#permitted_attributes` for `images: []`.)

**Phase C definition of done:** Admin can CRUD categories, products (including images), and **orders / order lines** without the console. **Met** for resources above; **Phase D** still adds cart, public checkout, and automations (totals, stock).

---

## Phase D — Cart & orders

### D.1 Cart storage

**Requirements (from product planning):**

- **Guest orders:** checkout and order creation **without** `User` — see A.3; do not gate `OrdersController` with `authenticate_user!`.
- **Cart ~30 days:** persist guest (and optionally logged-in) cart for return visits using **`Rails.cache`** (e.g. Solid Cache in production) with **`expires_in: 30.days`**, keyed by a stable signed token in cookies (e.g. `guest_cart_id`) or `user_id` when present. Session-only storage is insufficient for a 30-day window unless session cookie lifetime is explicitly extended — prefer cache + explicit TTL.

**Choose one for v1 (implementation detail):**

| Approach | Pros | Cons |
|----------|------|------|
| Session (serialized product ids + qty) | Simple, no login | Size limits; short TTL unless cookie max-age tuned |
| **`Rails.cache` + cookie key** (30d TTL) | Matches “come back within a month” | Must define key rotation / merge on login |
| `Cart` model + `session_id` / user | Clearer domain | More tables |

**Tasks:**

1. Service object or concern: `Cart#add`, `#remove`, `#line_items`, `#total`.
2. `CartsController` — show, update line qty, remove line.
3. Turbo: update cart partial on change (optional).

**Implemented (D.1):**

- **`Cart`** PORO: `Rails.cache` keys `cart/g/<token>` (signed cookie `cart_token`, httponly, permanent) and `cart/u/<user_id>`; **`expires_in: 30.days`** on write; `add`, `set_quantity`, `remove`, `line_items`, `total`, `item_count`.
- **`CurrentCart`** concern on **`ApplicationController`**: `current_cart`, **`cart_item_count`** (nav badge); guest token via **`ensure_guest_cart_token!`**.
- **`Cart.merge_guest_into_user!`** after **`SessionsController#create`** and **`RegistrationsController#create`** (guest cookie cleared after merge).
- **`CartsController`** (`allow_unauthenticated_access`): **`show`**, **`add`** (POST), **`update_line`** (PATCH), **`remove_line`** (DELETE); flash + `redirect_back` with fallback **`cart_path`**. Routes: **`resource :cart`** + member actions.
- Views: **`carts/show`**, **`products/_add_to_cart`**; layout **Кошик** links to **`cart_path`** with optional count.
- Tests: **`test/models/cart_test.rb`**, **`test/controllers/carts_controller_test.rb`**; **`config.cache_store = :memory_store`** in test so cart integration tests work. Run with **`bin/docker-test`** (see README).
- Turbo live cart partial: not implemented (optional).

### D.2 Orders

**Schema (implemented for admin — see C.2):** `orders` and `order_items` tables exist with `total` / `unit_price` as `decimal`, string `status`, optional `user_id`, shipping fields, `email` on `orders`.

**Migration sketch (historical):**

- `orders`: `user_id` (optional), `status` (enum: pending, confirmed, shipped, cancelled, …), `total_cents` or `total` decimal, shipping name/phone/address fields, `email`, timestamps.
- `order_items`: `order_id`, `product_id`, `quantity`, `unit_price` (**snapshot**), timestamps.

**Tasks:**

1. Checkout form: validate presence; create `Order` + `OrderItem` rows in a transaction; decrement `stock` (with row lock or `update_counters` to avoid races).
2. Clear cart on success.
3. Administrate: allow status updates; read-only financial fields if needed.

### D.3 Mailers (optional)

- [ ] `OrderMailer#confirmation` to customer.
- [ ] `OrderMailer#notify_admin` to shop email.

Configure `config/environments/production.rb` SMTP or transactional provider (SendGrid, Mailgun, Postmark, etc.).

**Phase D definition of done:** Happy-path purchase without payment; admin sees order; stock decreases; prices on line items frozen.

---

## Phase E — Polish & quality

### E.1 SEO & errors

- [ ] `meta-tags` gem (or manual `<title>` / `description` per product/category).
- [ ] `public/404.html`, `500.html` — localized static pages **or** dynamic errors with I18n.
- [ ] `sitemap.xml` generator (gem or rake task) for products/categories.

### E.2 Seeds & fixtures

- [ ] `db/seeds.rb`: categories, products with images (placeholders), one admin user (document password in README **only for dev** or use env).

### E.3 Tests (minimum bar)

- [ ] Model tests: validations, scopes, order creation + price snapshot.
- [ ] System test (optional): browse + add to cart + checkout.

### E.4 Security pass

- [ ] `force_ssl` in production.
- [ ] Secure headers (Rails defaults + review).
- [ ] Rate limit contact form / checkout (rack-attack optional).
- [ ] Active Storage: private bucket if files must not be public; otherwise S3/R2 with sane CORS.

**Phase E definition of done:** Demo-ready storefront; admin workflow complete; production config documented.

---

## Phase F — Late (after core is stable)

**Payments**

- Add provider gem or API client; webhook endpoint; idempotent order updates; never trust client-only confirmation.

**Telegram bot**

- Separate process or job; bot token in env; commands map to read-only or admin-only actions; reuse same `Order` records.

*(Detailed tasks omitted here—define when Phase E is shipped.)*

---

## Deployment

### 1. Production principles

| Topic | Guidance |
|-------|----------|
| **Secrets** | `RAILS_MASTER_KEY`, `SECRET_KEY_BASE`, DB URL, SMTP, storage keys — only via host secret manager or env, never in git |
| **Database** | Managed PostgreSQL (RDS, Render Postgres, Fly Postgres, Supabase, etc.) |
| **Assets** | `rails assets:precompile` in CI or release build; Tailwind must run in build pipeline |
| **Jobs** | Start with `async` / inline; add **Solid Queue** (Rails 8) or **Sidekiq + Redis** when you need background mail and webhooks |
| **Logging** | STDOUT logging for containers; aggregate on host if offered |

### 2. Pre-deploy checklist

- [ ] `config/environments/production.rb`: `config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?` or let reverse proxy serve `public/`.
- [ ] `config.active_storage.service` set to `:amazon` / `:s3_compatible` (Cloudflare R2, etc.) or keep `:local` only if single-server and persistent disk (not ideal on PaaS).
- [ ] `config.action_mailer.default_url_options` host = your real domain.
- [ ] `config.hosts << "yourdomain.com"` or regex for subdomains.
- [ ] Run `rails db:migrate` in release phase.
- [ ] Health route optional: `/up` (Rails 7.1+) for load balancers.

### 3. Deployment options (pick one)

#### Option A — Platform as a Service (simplest)

**Render / Fly.io / Railway (examples)**

1. Connect Git repo; set **build command** (e.g. `bundle install && bundle exec rails assets:precompile`).
2. Set **start command**: `bundle exec puma -C config/puma.rb` (or Dockerfile `CMD`).
3. Attach **managed Postgres**; paste `DATABASE_URL`.
4. Set env: `RAILS_ENV=production`, `RAILS_MASTER_KEY`, `SECRET_KEY_BASE` (if required by host).
5. Enable **auto deploy** on `main`.

**Docker on PaaS:** Push same `Dockerfile` as dev with production `RAILS_ENV` and multi-stage build if you want smaller images.

#### Option B — VPS (Docker Compose or Kamal)

1. Server: Ubuntu LTS; install Docker; firewall 22/80/443.
2. **Reverse proxy:** Caddy or Traefik or Nginx with Let’s Encrypt for TLS.
3. **Compose stack:** `web` + no local `db` if using managed Postgres; or `db` on same VPS with backups (you own backups).
4. **Kamal** (Rails default in newer guides): `kamal setup` / `kamal deploy` with registry + secrets; good when you outgrow a single PaaS app.

#### Option C — Kubernetes

Only if you already run clusters—overkill for a mini shop unless org mandates it.

### 4. Active Storage in production

- Prefer **object storage** (S3-compatible) so app instances stay stateless.
- Set bucket CORS if browser uploads go direct (optional advanced).
- Run `rails active_storage:install` already done in dev; migrations applied in prod.

### 5. CI/CD (recommended shape)

1. **On push / PR:** `bundle exec rubocop` (if used), `bin/rails test` inside the CI job’s Ruby image (same app as Docker), or mirror **`bin/docker-test`** locally.
2. **On merge to main:** build image or trigger PaaS deploy; run migrations in a **release** step (not during asset compile only).

### 6. Post-deploy

- [ ] Smoke test: home, product, checkout, admin login.
- [ ] Monitor: host metrics + optional Sentry / AppSignal / Honeybadger.
- [ ] Backup policy: automated DB snapshots + restore drill once.

### 7. Rollback

- PaaS: use host’s “rollback release” or redeploy previous Git SHA.
- VPS/Kamal: keep last good image tag; `kamal rollback` or compose image pin.

---

## Suggested file map (reference)

```
Dockerfile
docker-compose.yml
.env.example
config/
  database.yml
  locales/uk.yml, ru.yml
  routes.rb
app/
  controllers/
  models/
  views/
  javascript/controllers/   # Stimulus
db/
  migrate/
  seeds.rb
```

---

## Cross-reference

| Topic | Document |
|-------|----------|
| Stack, locales, deferred features | [PLAN.md](./PLAN.md) |
| Step-by-step tasks, deploy | This file (`DEVELOPMENT_PLAN.md`) |

When the Rails app exists, add a short **README.md** with “Quick start: Docker” and link both plans for collaborators.
