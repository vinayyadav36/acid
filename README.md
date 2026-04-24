# 🔬 ACID — Advanced Database Interface System

[![Go Version](https://img.shields.io/badge/Go-1.24+-00ADD8?style=for-the-badge&logo=go)](https://go.dev/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

A production-grade API that **automatically adapts to any PostgreSQL database** — no schema configuration required.
Ships with a full web UI, JWT auth, ClickHouse search, Redis caching, CDC sync, and Hadoop essentials.

---

## ⚡ 30-Second Start (Docker)

```bash
cp .env.example .env          # 1. copy config template
# edit .env → set DATABASE_URL at minimum
docker-compose up -d          # 2. start Postgres · Redis · ClickHouse · API
```

Open → **<http://localhost:8080/>**

> **Windows users:** double-click `start.bat` (Docker) or `scripts\start-backend.bat` (native Go).

---

## 📦 Installing Dependencies

### Go dependencies (required to build / run natively)

```bash
go mod download        # downloads all Go modules listed in go.mod / go.sum
go mod verify          # verify checksums
```

Key Go dependencies (`go.mod`):

| Package | Purpose |
|---------|---------|
| `github.com/jackc/pgx/v5` | PostgreSQL driver |
| `github.com/golang-jwt/jwt/v5` | JWT auth |
| `github.com/redis/go-redis/v9` | Redis client |
| `github.com/ClickHouse/clickhouse-go/v2` | ClickHouse driver |
| `github.com/joho/godotenv` | `.env` loader |
| `github.com/xuri/excelize/v2` | Excel/CSV report export |
| `golang.org/x/crypto` | Password hashing (bcrypt) |
| `golang.org/x/time` | Rate limiter |

### Python dependencies (analytics script only)

```bash
pip install -r requirements.txt
```

| Package | Purpose |
|---------|---------|
| `psycopg2-binary` | PostgreSQL driver for Python |
| `python-dotenv` | Load `.env` into `os.environ` |

Then run the analytics helper:

```bash
python scripts/analytics.py --report summary
python scripts/analytics.py --report cases    --output cases.csv
python scripts/analytics.py --report entities --top 20
python scripts/analytics.py --report audit    --days 7
```

---

## 🗂️ Project Structure

```text
acid/
│
├── 📄 README.md                ← you are here
├── 📄 .env.example             ← copy to .env and fill in secrets
├── 📄 .env                     ← your local config (git-ignored)
├── 📄 go.mod / go.sum          ← Go module manifest (go mod download)
├── 📄 requirements.txt         ← Python deps  →  pip install -r requirements.txt
├── 📄 Dockerfile               ← builds the API container image
├── 📄 docker-compose.yml       ← full local stack: Postgres + Redis + ClickHouse + API
├── 📄 .golangci.yml            ← linter config  →  golangci-lint run
├── 📄 start.bat / stop.bat     ← Windows Docker quick-start / stop
│
├── cmd/
│   └── api/
│       └── main.go             ← SERVER ENTRY POINT — wires all packages & starts HTTP server
│
├── internal/                   ← all Go business logic (private to this module)
│   ├── auth/                   ← JWT token issue & validation
│   ├── cache/                  ← Redis multi-layer cache
│   ├── clickhouse/             ← ClickHouse connection, CDC, entity search
│   ├── config/                 ← loads .env into typed Config struct
│   ├── database/               ← pgx pool, replica pool, dynamic & entity repos
│   ├── dbsearch/               ← cross-database keyword / ID search & PII masking
│   ├── hadoop/                 ← Hadoop essentials (HDFS · MapReduce · Sqoop planning)
│   ├── handlers/               ← HTTP handlers (one file per feature area)
│   ├── middleware/             ← rate-limiting, JWT auth, audit logging, panic recovery
│   ├── models/                 ← shared domain structs (User, ApiKey, Case …)
│   ├── pagination/             ← cursor-based pagination helpers
│   ├── pipeline/               ← CDC data-sync pipeline (detect → process → load)
│   ├── schema/                 ← auto-discovers tables & builds safe query plans
│   └── services/               ← record-level service layer
│
├── web/                        ← frontend (served by Go binary — no separate server needed)
│   ├── index.html              ← landing page
│   ├── login.html              ← sign-in
│   ├── register.html           ← sign-up
│   ├── dashboard.html          ← user dashboard & API-key management
│   ├── admin.html              ← admin panel (tables · search · reports)
│   ├── docs.html               ← interactive API docs (Scalar UI)
│   ├── style.css               ← shared Mars-theme design system
│   ├── app.js                  ← shared frontend JS
│   ├── assets/                 ← bundled third-party JS (scalar-standalone.js)
│   └── isolated/               ← standalone micro-UIs (hadoop-review)
│
├── databases/                  ← SQL schemas, seed data, data-generator
│   ├── init/00-schema.sql      ← Postgres schema (auto-run by Docker on first start)
│   ├── init-clickhouse.sql     ← ClickHouse schema
│   ├── categories.sql          ← lookup / seed data
│   ├── generator.go            ← synthetic-data generator (run via docker-compose)
│   ├── incoming/               ← hot folder for incoming CSV/JSON uploads
│   ├── archive/                ← processed-files archive
│   ├── admin_storage/          ← admin-uploaded DB-file workspace
│   ├── migrations/             ← future schema migrations
│   └── private_nosql/          ← JSON reference data (hadoop_review.json)
│
├── docs/                       ← developer reference docs & migration SQL
│   ├── database_schema.sql     ← full schema reference
│   └── migrations/             ← numbered migration files
│
└── scripts/                    ← operational helper scripts
    ├── analytics.py            ← offline analytics reports (needs requirements.txt)
    ├── setup.sh                ← first-time Linux setup
    ├── start.sh / start.bat    ← native Go build + run (Linux / Windows)
    ├── start-backend.*         ← backend only (Linux .sh / Windows .bat)
    ├── start-frontend.*        ← frontend only
    ├── start-fullstack.*       ← Docker deps + native Go binary
    ├── start-menu.bat          ← interactive Windows startup menu
    ├── stop-backend.sh         ← stop backend process
    ├── db-validate.sh          ← validate DB connectivity
    ├── deploy-check.sh         ← pre-deploy checklist
    ├── preflight.sh            ← environment preflight checks
    ├── generate_databases.sh   ← bulk DB generation helper
    ├── database-manager.bat    ← Windows DB management menu
    └── lsd-api.service         ← systemd unit file for Linux production
```

---

## 🚀 Running the Project

### Option A — Docker (recommended, zero setup)

```bash
# 1. Configure
cp .env.example .env
# Edit .env — DATABASE_URL is the only required change for local dev

# 2. Download Go deps (only needed if you want IDE support / native build)
go mod download

# 3. Start entire stack
docker-compose up -d

# 4. (Optional) Seed synthetic data
docker-compose run --rm generator
```

| Service | URL |
|---------|-----|
| Web app | <http://localhost:8080/> |
| API docs | <http://localhost:8080/docs> |
| Admin panel | <http://localhost:8080/admin> |
| Health check | <http://localhost:8080/api/health> |
| PGAdmin | <http://localhost:5050> · admin@acid.local / admin |
| Adminer | <http://localhost:8081> |

### Option B — Native Go (fastest for development)

```bash
# Prerequisites: Go 1.24+, PostgreSQL 15+ already running
cp .env.example .env
# Edit .env → set DATABASE_URL

go mod download          # fetch all Go dependencies
go run ./cmd/api         # build + start server on :8080
```

### Option C — Python analytics

```bash
pip install -r requirements.txt          # install Python deps (once)
cp .env.example .env                     # ensure DATABASE_URL is set
python scripts/analytics.py --report summary
```

### Windows one-click

| Script | What it does |
|--------|-------------|
| `start.bat` | Docker full-stack start |
| `stop.bat` | Docker full-stack stop |
| `scripts\start-backend.bat` | Native Go build + run |
| `scripts\start-fullstack.bat` | Docker deps + native Go binary |
| `scripts\start-menu.bat` | Interactive startup menu |

---

## ⚙️ Configuration (`.env`)

```bash
# ── Required ─────────────────────────────────────────────────────
PORT=8080
DATABASE_URL=postgres://user:password@localhost:5432/dbname
JWT_SECRET=change-this-to-a-random-32-char-string   # openssl rand -base64 32

# ── Optional — Read replica (for scaling reads) ───────────────────
DATABASE_REPLICA_URL=postgres://user:password@replica:5432/dbname

# ── Optional — Redis (caching) ────────────────────────────────────
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=

# ── Optional — ClickHouse (fast full-text search) ─────────────────
CLICKHOUSE_ADDR=localhost:9000
CLICKHOUSE_DB=acid
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=

# ── Feature flags ─────────────────────────────────────────────────
ENABLE_CDC=true           # sync Postgres → ClickHouse
ENABLE_DB_SEARCH=true     # enable intelligence / entity search routes

# ── Rate limits (requests / minute) ──────────────────────────────
RATE_LIMIT_ANONYMOUS=100
RATE_LIMIT_AUTHENTICATED=1000
RATE_LIMIT_AI_AGENT=5000
```

See `.env.example` for the full annotated reference with all options.

---

## 🔌 API Reference

### Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Create account |
| POST | `/api/auth/login` | Sign in → JWT |
| POST | `/api/auth/logout` | Sign out |
| GET | `/api/auth/me` | Current user info |

### Tables & Records

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tables` | List all auto-discovered tables |
| GET | `/api/tables/{table}/records` | Paginated records |
| GET | `/api/tables/{table}/search` | In-table search |
| GET | `/api/tables/{table}/schema` | Column schema |

### Search & Reports

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/search` | Global search (all tables) |
| GET | `/api/smart-search` | Auto-detect ID type + search |
| GET | `/api/reports` | Generate CSV / JSON report |
| GET | `/api/databases` | List managed databases |

### Intelligence

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/entities/{id}/profile` | Full entity profile |
| GET | `/api/admin/db-search` | Cross-DB keyword scan |

### Hadoop Essentials

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/hadoop/cluster` | NameNode / DataNode snapshot |
| POST | `/api/hadoop/mapreduce/wordcount` | Parallel word-count MapReduce |
| POST | `/api/hadoop/sqoop/plan` | Build Sqoop import/export plan |

```json
// Sqoop plan — request body example
{
  "direction": "import",
  "source":    "jdbc:postgresql://localhost:5432/acid",
  "target":    "/acid/raw/customers",
  "table":     "customers",
  "split_by":  "id",
  "mappers":   4
}
```

---

## 🏗️ Architecture

```text
  Clients (browser · mobile · bots · AI agents)
         │
         ▼
  ┌──────────────────────────────────────────┐
  │        ACID API  (Go · :8080)            │
  │  middleware: JWT · rate-limit · audit    │
  │  handlers:  auth · tables · search ·    │
  │             reports · entities · hadoop  │
  └───────┬──────────────┬───────────────────┘
          │              │
    ┌─────▼──────┐  ┌────▼───────┐
    │ PostgreSQL │  │ ClickHouse │  ← fast full-text search
    │  (primary) │  │  (search)  │
    └─────┬──────┘  └────────────┘
          │  CDC pipeline (async background sync)
    ┌─────▼──────┐
    │   Redis    │  ← caching layer
    └────────────┘
```

---

## 🛠️ Development

```bash
# Run all tests
go test ./...

# Lint
golangci-lint run

# Build binary
go build -o acid ./cmd/api

# Validate environment before deploy
bash scripts/preflight.sh
bash scripts/deploy-check.sh
```

### Key files to know

| File | Role |
|------|------|
| `cmd/api/main.go` | Entry point — wires all packages together |
| `internal/config/config.go` | Typed config struct loaded from `.env` |
| `internal/handlers/api_handlers.go` | Route registrations |
| `internal/schema/loader.go` | Auto-discovers Postgres tables |
| `internal/pipeline/cdc_pipeline.go` | Postgres → ClickHouse sync |
| `web/style.css` | Shared design system (Mars theme) |
| `docker-compose.yml` | Full local stack definition |

---

## 🐳 Docker Commands

```bash
docker-compose up -d           # start all services (detached)
docker-compose logs -f api     # tail API logs
docker-compose ps              # service status
docker-compose down            # stop & remove containers
docker-compose build           # rebuild images after code change
```

---

## 🧠 Hadoop Essentials

Integrated Hadoop building blocks (essentials model — no real Hadoop cluster required):

- **NameNode** namespace / cluster / checkpoint metadata model
- **DataNode** health and capacity snapshot
- **Secondary NameNode** checkpoint tracking
- **MapReduce** parallel word-count endpoint
- **Sqoop** import / export command plan builder

---

## 🙏 Support

- Issues: [GitHub Issues](https://github.com/vinayyadav36/acid/issues)
- Discussions: [GitHub Discussions](https://github.com/vinayyadav36/acid/discussions)

---

Built with ❤️ for easy database management — [⬆ Back to Top](#-acid--advanced-database-interface-system)
