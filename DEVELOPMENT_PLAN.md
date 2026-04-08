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

**Phase 0 — status:** Successfully passed for this repository (Docker-first path: Rails 8, PostgreSQL 16, Tailwind + Hotwire, Compose services `web` / `db` / `pgadmin`, `Dockerfile.dev` for dev and generated `Dockerfile` for production/Kamal). Use the host port published in `docker-compose.yml` for the app (e.g. `http://localhost:3000`).

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
- [x] Browser opens app at the mapped host URL (see `docker-compose.yml`; e.g. `http://localhost:3000`).

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
- [x] **`HomePromotion`** — home carousel + public **`/promotions/:slug`**; **`/admin/home_promotions`**; demo rows in **`db/seeds.rb`**. Details: **`docs/HOME_PROMOTIONS_PLAN.md`** and **README** (*Home page promotions*).
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
- **Cart UX:** **`add`** / **`update_line`** respond to **`turbo_stream`**: sync nav badges (desktop **cart icon + label**, **mobile header** icon, **mobile menu** cart row), replace per-product **`#add-to-cart-product-{id}`**; **`−` / `+`** stepper in grey bar when qty &gt; 0; **`animate-cart-line-appear`** on line refresh; **`#cart-toast`** only for errors. HTML still **`redirect_back`**. No disabled-button “✓” (was dropping rapid clicks).

### D.2 Orders

**Schema (implemented for admin — see C.2):** `orders` and `order_items` tables exist with `total` / `unit_price` as `decimal`, string `status`, optional `user_id`, shipping fields, `email` on `orders`.

**Migration sketch (historical):**

- `orders`: `user_id` (optional), `status` (enum: pending, confirmed, shipped, cancelled, …), `total_cents` or `total` decimal, shipping name/phone/address fields, `email`, timestamps.
- `order_items`: `order_id`, `product_id`, `quantity`, `unit_price` (**snapshot**), timestamps.

**Tasks:**

1. Checkout form: validate presence; create `Order` + `OrderItem` rows in a transaction; decrement `stock` (with row lock or `update_counters` to avoid races).
2. Clear cart on success.
3. Administrate: allow status updates; read-only financial fields if needed.

**Implemented (D.2):**

- Migration **`public_token`** on `orders` (unique); guest-safe confirmation URL **`/o/:public_token`**.
- **`Checkout`** PORO (`app/models/checkout.rb`, same autoload pattern as **`Cart`**): pessimistic lock active products, validate `Order` with **`:checkout`** (email + shipping fields), snapshot **`unit_price`**, **`recalculate_total!`**, decrement stock, **`cart.clear`** on success; roll back on validation or stock errors.
- **`CheckoutsController`** (`new` / `create`), **`OrderConfirmationsController#show`**; routes **`resource :checkout`**, **`order_confirmation_path`**.
- Views: **`checkouts/new`**, **`order_confirmations/show`**; cart CTA **`carts.checkout_cta`** → **`new_checkout_path`**.
- Administrate: **`total`** removed from order **form** (still on show); **`public_token`** on show.
- Tests: **`test/services/checkout_test.rb`**, **`test/controllers/checkouts_controller_test.rb`**.

### D.3 Mailers (optional)

- [x] `OrderMailer#confirmation` to customer (after successful checkout, `deliver_later`).
- [x] `OrderMailer#notify_admin` to **`ENV["SHOP_NOTIFICATION_EMAIL"]`** when set (same hook).
- [x] **`MAILER_FROM`** default on `ApplicationMailer`; development uses **`:test`** delivery unless **`SMTP_*`** set; production configures **SMTP** when **`SMTP_ADDRESS`** is present (**`MAILER_HOST`**, **`MAILER_PROTOCOL`** for URL helpers).
- [x] Tests: **`test/mailers/order_mailer_test.rb`**, checkout controller asserts **`assert_emails`** + **`perform_enqueued_jobs`**; previews **`test/mailers/previews/order_mailer_preview.rb`**.

**D.3 — deferred / ops (revisit later):**

- **`From:` / `MAILER_FROM`:** Must be visible inside the **`web`** container (`docker compose exec web env | grep MAILER`). Compose uses **`env_file: .env`**; no `export` in `.env`, UTF‑8 BOM can break the value — strip in code. **`ApplicationMailer#mail`** merges **`**kwargs`** so `mail(to:, subject:)` is not lost; **`OrderMailer`** also passes **`from: mailer_from_address`** explicitly. If **`From`** still shows **`noreply@example.com`**, the variable is empty in the running container — fix env, then rebuild/restart **`web`**.
- **Verbose MIME in logs:** Not fixable via `Mail.logger=` on mail 2.9. **`docker-compose`** sets **`RAILS_LOG_LEVEL`** default **`info`** for **`web`** (override with **`RAILS_LOG_LEVEL=debug`** in `.env` when you need SQL detail). Gmail SMTP: **`MAILER_FROM`** should match **`SMTP_USERNAME`** unless “Send mail as” is configured.

**Phase D definition of done:** Happy-path purchase without payment; admin sees order; stock decreases; prices on line items frozen.

---

## Phase E — Polish & quality

### E.1 SEO & errors

- [x] **`meta-tags`** gem; default title/description in **`ApplicationController`**; per-page tags for home, catalog, product (**`og:image`** when images exist), category, delivery, contacts, cart/checkout/confirmation (**`noindex`**).
- [x] Dynamic **I18n** error pages via **`config.exceptions_app`** → **`ErrorsController`** (`/404`, `/500`), **`Accept-Language`** hint for uk/ru; static English fallbacks live at **`public/fallback_404.html`** / **`fallback_500.html`** (not `404.html` — that path is reserved by the static file server and would shadow the localized routes).
- [x] **`/sitemap.xml`** (`SitemapsController` + **`show.xml.builder`**: root, catalog, products index, static pages, all categories/products); **`/robots.txt`** (`RobotsController`) with **`Disallow: /admin`** and **Sitemap** URL. Production: **`config.action_controller.default_url_options`** aligned with **`MAILER_HOST`** / **`MAILER_PROTOCOL`** for absolute URLs.

### E.2 Seeds & fixtures

- [x] `db/seeds.rb`: categories, products with images (placeholders), one admin user (document password in README **only for dev** or use env).

### E.3 Tests (minimum bar)

- [x] Model tests: validations, scopes, order creation + price snapshot.
- [x] System test (optional): browse + add to cart + checkout.

### E.4 Security pass

- [x] `force_ssl` in production.
- [x] Secure headers (Rails defaults + review).
- [x] Rate limit contact form / checkout (rack-attack optional).
- [x] Active Storage: private bucket if files must not be public; otherwise S3/R2 with sane CORS.

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

### Current readiness & next steps

This subsection summarizes **what the repo already provides** for going live, **what is still configuration work**, and a **concrete order of operations**. Phases **A–E** in this document are largely implemented; **Phase F** (payments, Telegram) remains deferred per [PLAN.md](./PLAN.md).

#### Repository snapshot

| Area | Status |
|------|--------|
| **Storefront** | Catalog (filters, Turbo frame), product detail, cart (cache + long-lived guest cookie), checkout, order confirmation, guest and logged-in flows. |
| **Admin** | Administrate: categories, products (Active Storage images), orders, users, home promotions; public `/promotions/:slug`. |
| **Mail** | Order confirmation + optional shop alert; production SMTP via env (`SMTP_*`, `MAILER_HOST`, `MAILER_PROTOCOL`). |
| **SEO & errors** | Meta tags, sitemap, robots, localized `/404` and `/500`; static English fallbacks: `public/fallback_404.html`, `public/fallback_500.html` (for CDN/nginx — do not use `404.html` on URL `/404`, see Phase E.1). |
| **Security (prod)** | `assume_ssl` / `force_ssl` (env toggles), Rack::Attack on POST `/checkout` and `/contacts`. |
| **Tests & CI** | Minitest suite; GitHub Actions: Brakeman, bundler-audit, importmap audit, RuboCop, `bin/rails test`, `test:system`. |
| **Containers** | `Dockerfile` (production build, assets, Thruster); dev via `docker-compose.yml` / `Dockerfile.dev`. |
| **Kamal** | `config/deploy.yml` is a **template** (placeholder hosts/registry) — not production-ready until you replace servers, registry, proxy, and `.kamal/secrets`. |
| **Deferred** | Payment gateways and Telegram bot (Phase F) — design orders accordingly before adding providers. |

#### Gaps before a real production cutover

| Topic | Notes |
|-------|--------|
| **PostgreSQL (multi-DB)** | `config/database.yml` production defines **primary**, **cache**, **queue**, and **cable** databases. Create all four (or equivalent URLs) and run **all** required migrations in release — not only `db:migrate` for primary. Single-URL PaaS Postgres may need env alignment with Rails multi-DB docs. |
| **Active Storage** | Production defaults to **`:local`**; Kamal template mounts `app_storage`. For multiple app instances or ephemeral disks, switch to **S3/R2** in `config/storage.yml` and env. |
| **`config.hosts`** | Set real hostnames in `config/environments/production.rb` (or env-driven allowlist) to avoid `HostAuthorization` errors. |
| **Secrets / env** | At minimum: `RAILS_MASTER_KEY`, `SECRET_KEY_BASE` (if required by host), database credentials or `DATABASE_URL`, `MAILER_*` and `SMTP_*` for real mail, production admin credentials. See `.env.example` and README *Production security*. |
| **Seeds** | `db:seed` is appropriate for **dev/staging**. In **production**, prefer creating an admin via console or a controlled task — avoid default seed passwords and optional network image fetches unless intended. |
| **Static assets** | Either serve via the app (e.g. Thruster / `RAILS_SERVE_STATIC_FILES`) or offload `public/` to nginx/CDN — match your host’s recommendation. |
| **Background jobs** | Mail uses `deliver_later`; Solid Queue uses the **queue** DB. Ensure queue migrations ran and the host runs workers or **SOLID_QUEUE_IN_PUMA** (as in Kamal template) consistently with your topology. |

#### Recommended sequence

1. **Choose one path first:** managed **PaaS** (Render, Fly.io, Railway, etc.) for speed, or **VPS + Kamal** for full control — avoid splitting attention on the first deploy.
2. **Staging:** New app + DB, set `config.hosts`, mail env (or accept no outbound mail initially), run migrations for **all** DB roles, deploy (e.g. repo `Dockerfile`), smoke: `/`, product, cart → checkout, `/admin`, `/up`, `/sitemap.xml`.
3. **Hardening:** Production admin user, rotate any seed-related passwords, confirm job processing for mail.
4. **Production:** DNS, TLS, backups on Postgres, optional error tracking (Sentry, AppSignal, etc.).
5. **Product:** When you need online payment, plan **Phase F** (provider, webhooks, idempotent order updates).

#### Should you try to deploy?

**Yes — on staging first.** The application is **feature-complete for a non-payment storefront**; remaining work is mostly **host-specific configuration**. A first deploy on a PaaS free/staging tier or a single VPS surfaces DB, env, and TLS issues early without committing to production DNS.

---

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
