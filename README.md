# Budinfo

Rails 8 storefront + Administrate admin. **Develop and run commands with Docker** so Ruby, PostgreSQL, and gems match CI and teammates.

## Quick start (Docker)

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows: WSL2 backend recommended).
2. From the project root:

   ```sh
   docker compose up --build
   ```

3. Open the app at **http://localhost:3000** (host port is mapped in `docker-compose.yml`).

4. First-time database (if needed):

   ```sh
   bin/docker-rails db:prepare
   ```

5. Optional demo data: **`bin/docker-rails db:seed`** loads demo categories, products (Wikimedia images when the network allows), **HomePromotion** slides, and an admin user **admin@example.com**. Set **`ADMIN_SEED_PASSWORD`** in **`.env`** for a non-default password; otherwise seeds use **`changeme_in_production`** (dev only — never use in real production).

### Common commands (always use these, not host `ruby` / `bin/rails`)

Run these **on your machine** from the project root (they call `docker compose` for you). **Do not** run them inside the `web` container — Docker is not available there.

| Task | Command |
|------|---------|
| Rails console | `bin/docker-rails console` |
| Migrations | `bin/docker-rails db:migrate` |
| Tests | `bin/docker-test` |
| Single test file | `bin/docker-test test/models/cart_test.rb` |
| Prepare test DB | `bin/docker-test-prepare` |

On **Windows**, use **Git Bash** or **WSL** so the `bin/docker-*` scripts run; or invoke the same `docker compose run --rm …` lines from PowerShell (see `bin/docker-rails` for test env vars).

`bin/docker-rails` detects tasks that need the test database (`test`, `test:*`, `db:test:*`) and sets `RAILS_ENV=test` plus `DATABASE_URL` for **`app_test`**. Override with **`DOCKER_TEST_DATABASE_URL`** if your Compose credentials differ.

### Compose services

- **`web`** — Rails + Tailwind (port **3000** → container 3000).
- **`db`** — PostgreSQL 16 (`app_development`; tests use **`app_test`** via URL above).
- **`pgadmin`** — optional UI (see `docker-compose.yml` for port).

### Email (orders)

The **`web`** service loads **`env_file: .env`** — put **`MAILER_FROM`**, **`SMTP_*`**, and **`SHOP_NOTIFICATION_EMAIL`** there (see **`.env.example`**). If **`.env` is missing**, create an empty file or `docker compose` will fail on `env_file`.

After checkout, **`OrderMailer#confirmation`** goes to the customer; if **`SHOP_NOTIFICATION_EMAIL`** is set, **`notify_admin`** goes to the shop. **Without `SMTP_ADDRESS`**, development uses the **`:test`** adapter: **no real delivery** (only **`ActionMailer::Base.deliveries`** after jobs run). Add Gmail SMTP variables to **`.env`** and restart **`web`** to send for real. Large **base64 / MIME blocks in logs** usually mean log level is **debug** or the mail body is being printed when the job runs — they are not proof the message reached an inbox.

Mail previews: **`/rails/mailers`** (development).

### Without Docker

Local Ruby is not documented for this repo; prefer Docker for consistency.

## Home page promotions (carousel)

- **Storefront:** Active slides render on **`/`** (below the intro); each links to **`/promotions/:slug`**. Carousel autoplay and arrows are handled by Stimulus (`promotion-carousel`).
- **Admin:** Sign in as an **admin** user → **`/admin/home_promotions`** (Administrate). Create slides with **title**, **teaser**, **slug** (URL segment), **body** (detail page), **position**, **active**, and **image**. Active rows **require** an image.
- **Demo data:** After **`bin/docker-rails db:seed`** (or `db:seed` in the `web` container), sample promos include **`demo-cement-week`** and **`demo-insulation`** (Wikimedia images; see comment block at the top of **`db/seeds.rb`**). Inactive **`demo-draft`** does not appear on the home page.

See **`docs/HOME_PROMOTIONS_PLAN.md`** for the full feature checklist.

## Production security (summary)

- **HTTPS:** Production enables **`assume_ssl`** and **`force_ssl`** by default (TLS-terminated proxy). Override with **`RAILS_ASSUME_SSL`** / **`RAILS_FORCE_SSL`** only for special cases (see **`.env.example`**).
- **Throttling:** **Rack::Attack** limits POST **`/checkout`** and **`/contacts`** per IP in production (`config/initializers/rack_attack.rb`).
- **Headers:** Rails default security headers apply; tighten **CSP** via **`config/initializers/content_security_policy.rb`** after validating the storefront in-browser.
- **Active Storage:** For cloud storage, use **`config/storage.yml`** (**`:amazon`** or S3-compatible). Prefer **non-public** buckets when uploads must not be world-readable; configure **CORS** if you add direct uploads.

## Further planning

See **`DEVELOPMENT_PLAN.md`** for phases, schema notes, and operational details. For **deploy readiness** (what is done vs what to configure), **multi-DB / Active Storage / hosts**, and a **recommended staging-first sequence**, read the **Deployment → Current readiness & next steps** section there.
