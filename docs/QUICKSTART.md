# 🚀 ACID Quick Start Guide

This guide will get you up and running with ACID in 5 minutes!

---

## Prerequisites

Before starting, make sure you have:

| Software | Required | Notes |
|----------|----------|-------|
| Git | Yes | For cloning the project |
| Docker | Yes-recommended | Easiest way to run |
| Go 1.24+ | Optional | Only if running without Docker |
| PostgreSQL 15+ | Yes | Your database |

---

## Step 1: Clone the Project

```bash
git clone <this-repo>
cd acid
```

## Step 2: Quick Start with Docker (Recommended)

### Option A: Use Our Quick Start Script

```bash
# Make scripts executable
chmod +x scripts/setup.sh

# Run the setup
./scripts/setup.sh
```

### Option B: Manual Docker Setup

```bash
# 1. Copy the environment template
cp .env.example .env

# 2. Edit the .env file with your database URL
#    DATABASE_URL=postgres://user:password@localhost:5432/yourdb
#    
#    Example:
#    DATABASE_URL=postgres://myuser:mypassword@localhost:5432/production

# 3. Start all services
docker-compose up -d

# 4. Wait for services to start (about 10-15 seconds)

# 5. Check status
docker-compose ps
```

---

## Step 3: Access the Application

Open your browser and go to:

| URL | What You'll See |
|-----|----------------|
| [`http://localhost:8080/admin`](http://localhost:8080/admin) | **Main Admin Panel** ⭐ |
| [`http://localhost:8080/`](http://localhost:8080/) | Home Page |
| [`http://localhost:8080/login`](http://localhost:8080/login) | Login Page |
| [`http://localhost:8080/docs`](http://localhost:8080/docs) | API Documentation |

### First Login

1. Go to `/register`
2. Create your account
3. Login with your credentials
4. You're in! 🎉

---

## What Can You Do in the Admin Panel?

### 1. 📊 Dashboard
- See total databases, tables, and records
- View system health (PostgreSQL, Redis, ClickHouse status)
- See quick stats

### 2. 📋 Tables
- Browse ALL tables in your database automatically
- View records with pagination
- Search within any table
- See table schema (columns, types, indexes)

### 3. 🔍 Global Search
- Search across ALL tables at once
- Find duplicates across databases
- Get results in milliseconds

### 4. 🗄️ Databases
- View multiple databases
- See sync status
- Trigger manual sync

### 5. 📄 Reports
- Download data as CSV (for Excel)
- Download as JSON
- Download as PDF/Text
- Filter by search term
- Limit records

### 6. ⚙️ Settings
- Configure JWT secret
- Set rate limits
- Enable/disable CDC

---

## Adding Your Database Files

If you have database SQL files:

1. Place them in the `databases/` folder
2. They will be automatically loaded when Docker starts
3. Or execute them manually:

```bash
# Connect to PostgreSQL container
docker exec -it acid-postgres psql -U lsd -d lsd

# Run your SQL
\i /docker-entrypoint-initdb.d/your-file.sql
```

---

## 🚨 Troubleshooting

### "Database Not Connected"

```
✅ Check:
1. Is PostgreSQL running?
   docker-compose ps

2. Is DATABASE_URL correct in .env?
   cat .env | grep DATABASE_URL

3. Can you connect directly?
   docker exec -it acid-postgres psql -U lsd -d lsd
```

### "Can't Login"

```
✅ Solutions:
1. Go to /register to create an account
2. Check your password is correct
3. Try clearing browser cookies
```

### "No Tables Showing"

```
✅ Solutions:
1. Check your database has tables: 
   docker exec -it acid-postgres psql -U lsd -d lsd -c "\dt"

2. Ensure user has permission:
   GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO lsd;
```

### "Search Not Working"

```
✅ Solutions:
1. ClickHouse might be offline - that's OK!
2. Search still works using PostgreSQL (slightly slower)
3. Status shows ClickHouse as "Offline" but search works
```

---

## Running Without Docker

If you prefer running natively:

```bash
# 1. Install Go 1.24+
go version

# 2. Install dependencies
go mod download

# 3. Set environment variables
export DATABASE_URL=postgres://user:password@localhost:5432/yourdb
export REDIS_ADDR=localhost:6379
export CLICKHOUSE_ADDR=localhost:9000

# 4. Run
go run ./cmd/api

# 5. Open http://localhost:8080/admin
```

---

## 📋 Common Commands Reference

```bash
# Docker
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose logs -f           # View logs
docker-compose restart api         # Restart API
docker-compose ps                # Check status

# Database
docker exec -it acid-postgres psql -U lsd -d lsd   # Connect to DB

# Redis
docker exec -it acid-redis redis-cli ping           # Test Redis
```

---

## 🔧 Configuration

Edit `.env` file for custom configuration:

```bash
# Required
DATABASE_URL=postgres://user:password@host:5432/dbname

# Optional - Redis (for caching)
REDIS_ADDR=localhost:6379

# Optional - ClickHouse (for fast search)
CLICKHOUSE_ADDR=localhost:9000

# Optional - Features
ENABLE_CDC=true
ENABLE_DB_SEARCH=true
```

---

## 🎉 You're Ready!

Now go to **[http://localhost:8080/admin](http://localhost:8080/admin)** and start managing your database!

Need more help? Check the [User Guide](docs/README-FOR-USERS.md) or [API Documentation](docs/architecture.md).