# 🔬 ACID - Advanced Database Interface System

<div align="center">

**A production-grade, high-performance API that automatically adapts to any PostgreSQL database**

[![Go Version](https://img.shields.io/badge/Go-1.24+-00ADD8?style=for-the-badge&logo=go)](https://go.dev/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

[🚀 Quick Start](#quick-start) · [📖 User Guide](docs/README-FOR-USERS.md) · [⚙️ Configuration](docs/configuration.md) · [🎮 Demo](#features)

</div>

---

## 📋 What is ACID?

**ACID (Advanced Database Interface System)** is a powerful system that gives you a beautiful web interface to manage your PostgreSQL database - without writing any code!

Think of it like this:
- **PostgreSQL** = Your filing cabinet (where all data is stored)
- **ACID** = A smart assistant that helps you find, organize, and manage files
- **ClickHouse** = A super-fast search engine that finds anything instantly
- **Redis** = Sticky notes for faster access

---

## ✨ Features

| Feature | What It Does |
|---------|-------------|
| 🔮 **Auto-Discovery** | Automatically finds all your database tables - no setup needed! |
| ⚡ **Fast Search** | Searches billions of records in milliseconds using ClickHouse |
| 🎨 **Admin Panel** | Beautiful web interface at `/admin` |
| 📊 **Reports** | Download data as CSV, JSON, or PDF |
| 🔐 **Security** | JWT authentication, rate limiting, audit logging |
| 🔄 **CDC Sync** | Automatically syncs data to search engine |
| 📦 **Caching** | Redis caching for lightning-fast responses |

---

## 🚀 Quick Start

### Option 1: Docker (Recommended)

```bash
# 1. Clone the project
git clone <this-repo>
cd acid

# 2. Copy configuration
cp .env.example .env

# 3. Edit .env with your database details
nano .env

# 4. Start everything
docker-compose up -d

# 5. Open your browser
#    Admin Panel: http://localhost:8080/admin
#    API Docs:     http://localhost:8080/docs
```

### Option 2: Manual Setup

```bash
# 1. Install prerequisites
#    - Go 1.24+
#    - PostgreSQL 15+
#    - Redis (optional)
#    - ClickHouse (optional for fast search)

# 2. Clone and enter project
git clone <this-repo>
cd acid

# 3. Copy configuration
cp .env.example .env

# 4. Edit .env with your database URL
#    DATABASE_URL=postgres://user:password@localhost:5432/yourdb

# 5. Download dependencies
go mod download

# 6. Run the server
go run ./cmd/api

# 7. Open browser
#    http://localhost:8080/admin
```

---

## 🌐 Access Points

Once running, access these URLs:

| URL | Purpose |
|-----|---------|
| [`http://localhost:8080/admin`](http://localhost:8080/admin) | **Complete Admin Panel** - Use this! |
| [`http://localhost:8080/`](http://localhost:8080/) | Home page |
| [`http://localhost:8080/login`](http://localhost:8080/login) | User login |
| [`http://localhost:8080/register`](http://localhost:8080/register) | Create account |
| [`http://localhost:8080/docs`](http://localhost:8080/docs) | API Documentation |
| [`http://localhost:8080/api/health`](http://localhost:8080/api/health) | Health check |

---

## 📖 User Guide

For detailed instructions on using ACID, see [📖 User Guide](docs/README-FOR-USERS.md)

### What can you do in the Admin Panel?

1. **📊 Dashboard** - See overview of all databases, tables, records
2. **📋 Tables** - Browse and search any table
3. **🔍 Search** - Global search across ALL tables at once
4. **🗄️ Databases** - Manage multiple databases
5. **📄 Reports** - Download data in CSV/JSON/PDF format
6. **👥 Users** - Manage user accounts
7. **⚙️ Settings** - Configure system settings

---

## ⚙️ Configuration

All configuration is in the `.env` file. Key options:

```bash
# Server
PORT=8080

# Database (Required)
DATABASE_URL=postgres://user:password@host:5432/dbname

# Redis (Optional - for caching)
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=

# ClickHouse (Optional - for fast search)
CLICKHOUSE_ADDR=localhost:9000
CLICKHOUSE_DB=acid
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=

# Security
JWT_SECRET=change-this-in-production

# Features
ENABLE_CDC=true
ENABLE_DB_SEARCH=true
```

See [Configuration Guide](docs/configuration.md) for all options.

---

## 🔌 API Endpoints

### Authentication
| Endpoint | Method | Description |
|-----------|---------|-------------|
| `/api/auth/register` | POST | Create new account |
| `/api/auth/login` | POST | Sign in |
| `/api/auth/logout` | POST | Sign out |
| `/api/auth/me` | GET | Get current user |

### Tables
| Endpoint | Method | Description |
|-----------|---------|-------------|
| `/api/tables` | GET | List all tables |
| `/api/tables/{table}/records` | GET | Get records |
| `/api/tables/{table}/search` | GET | Search in table |
| `/api/tables/{table}/schema` | GET | Get table schema |

### Search
| Endpoint | Method | Description |
|-----------|---------|-------------|
| `/api/search` | GET | Global search |
| `/api/search/duplicates` | GET | Search with duplicate detection |

### Reports
| Endpoint | Method | Description |
|-----------|---------|-------------|
| `/api/reports` | GET | Generate report |
| `/api/databases` | GET | List databases |

### Intelligence (Optional)
| Endpoint | Method | Description |
|-----------|---------|-------------|
| `/api/smart-search` | GET | AI-powered search |
| `/api/entities/{id}/profile` | GET | Entity profile |

See [API Documentation](docs/architecture.md) for complete endpoint list.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTS                              │
│   (Web Browser, Mobile App, API Consumers, Bots)            │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    ACID API SERVER                         │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │  Auth        │ │  Rate Limit  │ │    Logger    │      │
│  │  (JWT)       │ │  (Security) │ ��  (Logging)  │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
│         │                                                 │
│  ┌──────┴──────────────────────────────────────┐          │
│  │           HANDLERS                          │          │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐       │          │
│  │  │Dynamic  │ │Report   │ │Entity   │       │          │
│  │  │Handler  │ │Handler  │ │Handler  │       │          │
│  │  └─────────┘ └─────────┘ └─────────┘       │          │
│  └──────┬──────────────────────────────────────┘          │
│         │                                                 │
│  ┌──────┴──────────────────────────────────────┐          │
│  │              SERVICES                        │          │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐   │          │
│  │  │ Schema   │ │Database │ │ Cache    │   │          │
│  │  │Discovery│ │ Pool    │ │ (Redis)  │   │          │
│  │  └──────────┘ └──────────┘ └──────────┘   │          │
│  └──────┬──────────────────────────────────────┘          │
└─────────┼───────────────────────────────────────────────────┘
          │
    ┌─────┴───────────────────────────────────────────────────┐
    │                       DATABASES                            │
    │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐     │
    │  │PostgreSQL   │ │ClickHouse    │ │   Redis      │     │
    │  │(Main DB)    │ │(Search)      │ │(Cache)       │     │
    │  └──────────────┘ └──────────────┘ └──────────────┘     │
    └───────────────────────────────────────────────────────────┘
```

---

## 🐳 Docker Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild containers
docker-compose build

# View running containers
docker-compose ps
```

---

## 🛠️ Development

### Project Structure

```
acid/
├── cmd/api/              # Main application entry point
├── internal/
│   ├── auth/            # Authentication (JWT)
│   ├── cache/           # Redis caching
│   ├── clickhouse/      # ClickHouse integration
│   ├── config/          # Configuration
│   ├── database/        # Database connections
│   ├── dbsearch/        # Entity search
│   ├── handlers/        # HTTP request handlers
│   ├── middleware/      # Security middleware
│   ├── pipeline/        # Data processing
│   └── schema/           # Schema discovery
├── web/                  # Frontend (HTML/CSS/JS)
│   ├── admin.html       # Admin panel
│   ├── dashboard.html   # User dashboard
│   └── style.css        # Styling
├── databases/            # Database scripts
├── docs/                 # Documentation
├── scripts/             # Automation scripts
└── docker-compose.yml   # Docker configuration
```

### Important Files

| File | Purpose |
|------|---------|
| `cmd/api/main.go` | Main application - Don't modify unless adding features |
| `internal/config/config.go` | Settings - Don't modify unless changing defaults |
| `internal/database/pool.go` | Database connection - Don't modify |
| `web/admin.html` | Admin panel - You can customize UI here |
| `.env` | Your configuration - Edit this! |

---

## 📚 Documentation

| Document | What It Covers |
|----------|---------------|
| [User Guide](docs/README-FOR-USERS.md) | How to use the Admin Panel |
| [Architecture](docs/architecture.md) | System design and components |
| [Configuration](docs/configuration.md) | All settings explained |
| [Setup Guide](docs/setup.md) | Step-by-step installation |
| [Development](docs/development.md) | For developers |
| [Deployment](docs/deployment.md) | Production deployment |

---

## ❓ FAQ

Common questions answered in [FAQ](docs/faq.md)

---

## 🙏 Support

- Issues: [GitHub Issues](https://github.com/Daveshvats/ACID/issues)
- Discussions: [GitHub Discussions](https://github.com/Daveshvats/ACID/discussions)

---

<div align="center">

**Built with ❤️ for easy database management**

[⬆ Back to Top](#acid---advanced-database-interface-system)

</div>