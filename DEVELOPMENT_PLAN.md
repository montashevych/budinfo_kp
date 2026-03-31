# Detailed development & deployment plan

This document expands [PLAN.md](./PLAN.md) into **actionable tasks**, **checklists**, and a **deployment** path. Use it as a day-by-day guide; adjust estimates to your pace.

---

## How to use this document

1. Work **phases in order** (A → F). Later phases assume earlier ones exist.
2. Check off **Definition of done** items before moving on.
3. Run **`rails test`** (or RSpec) after each vertical slice when you add tests.
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

### 0.3 Git hygiene

- [x] `.gitignore` includes `/log`, `/tmp`, `/storage`, `.env`, `master.key` handling per Rails docs.
- [x] `config/master.key` **not** committed; use `RAILS_MASTER_KEY` in production.

**Phase 0 definition of done:** App boots in Docker; DB connects; Tailwind builds; Hotwire loads on a smoke page. **Done for this repo.**

---

## Phase A — Foundation

**Phase A — status:** A.1 (I18n) and A.2 (layout + static skeleton) implemented: default locale `uk`, optional `ru`, no `:en` in `available_locales`, fallbacks `ru → uk`. A.3 (Devise) not started yet.

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

### A.3 Devise (or Rails 8 native auth)

**Tasks:**

1. Add **Devise**; `rails g devise User`.
2. Add **role** to `users`: `enum :role, { customer: 0, admin: 1 }` (or string enum—pick one convention).
3. First user seed or console: promote one admin.

**Checklist:**

- [ ] Sign up / sign in / sign out work in `:uk` / `:ru` Devise views (generate views + translate or use I18n YAML).

**Phase A definition of done:** Localized shell of the site; auth works; Docker workflow is routine. *(Auth / A.3 still to do.)*

---

## Phase B — Catalog

### B.1 Categories

**Migration sketch:**

- `categories`: `name_uk`, `name_ru` (or single `name` + JSON/translations later), `slug` (unique, indexed), `parent_id` (optional, self-referential).

**Tasks:**

1. `rails g model Category ...`
2. Model: `friendly_id` or manual slug validation; `has_many :products`.
3. Controller: `CategoriesController#index`, `#show` (by slug).
4. Views: list + show with product grid partial.

**Checklist:**

- [ ] Slugs are unique; invalid slugs 404.

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

- [ ] Filters cannot inject SQL (use bound parameters / scopes only).
- [ ] Inactive products not listed; direct slug access returns 404 or “unavailable” per your policy.

### B.3 Turbo / Stimulus touches

- [ ] Pagination: `turbo_frame` or full page—pick one and stay consistent.
- [ ] “Add to cart” button exists as stub (disabled or Phase D)—optional link to Phase D.

**Phase B definition of done:** Full browse path: categories → filtered list → product detail with images; copy in Ukrainian/Russian per DB fields + I18n chrome.

---

## Phase C — Administrate

### C.1 Install & namespace

**Tasks:**

1. Add `administrate` gem; run install generator.
2. Mount dashboards under `/admin`.
3. **Authenticate**: `before_action` requiring `current_user.admin?` (or Devise `authenticate_user!` + role check).
4. Consider **Pundit** for `Admin::ApplicationController` policies if you split permissions later.

### C.2 Dashboards

Register resources:

- [ ] `Category`
- [ ] `Product` (show image attachments in form or custom field)
- [ ] `User` (read-only or limited fields—avoid exposing tokens)
- [ ] `Order`, `OrderItem` (after Phase D—can stub routes after models exist)

**Checklist:**

- [ ] Non-admin users get 403/redirect from `/admin`.
- [ ] Strong params in Administrate overrides match your model attributes.

**Phase C definition of done:** Admin can CRUD categories and products (including images) without touching the console.

---

## Phase D — Cart & orders

### D.1 Cart storage

**Choose one for v1:**

| Approach | Pros | Cons |
|----------|------|------|
| Session (serialized product ids + qty) | Simple, no login | Size limits; no cross-device |
| `Cart` model + `session_id` / user | Clearer domain | More tables |

**Tasks:**

1. Service object or concern: `Cart#add`, `#remove`, `#line_items`, `#total`.
2. `CartsController` — show, update line qty, remove line.
3. Turbo: update cart partial on change (optional).

### D.2 Orders

**Migration sketch:**

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

1. **On push / PR:** `bundle exec rubocop` (if used), `rails test`.
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
