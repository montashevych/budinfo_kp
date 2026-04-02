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

### Without Docker

Local Ruby is not documented for this repo; prefer Docker for consistency.

## Further planning

See **`DEVELOPMENT_PLAN.md`** for phases, schema notes, and operational details.
