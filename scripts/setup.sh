#!/bin/bash
# =============================================================================
# ACID Quick Setup & Run Script
# =============================================================================
# This script sets up and runs ACID using Docker
# 
# Usage: ./scripts/setup.sh
# =============================================================================

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           ACID - Quick Setup & Run                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 found"
        return 0
    else
        echo -e "${RED}✗${NC} $1 NOT found"
        return 1
    fi
}

echo -e "${YELLOW}=============================================${NC}"
echo -e "${YELLOW}Checking prerequisites...${NC}"
echo -e "${YELLOW}=============================================${NC}"
check_command docker
check_command docker-compose

echo ""
echo -e "${YELLOW}=============================================${NC}"
echo -e "${YELLOW}Setting up configuration...${NC}"
echo -e "${YELLOW}=============================================${NC}"

# Create .env from example if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✓${NC} Created .env from template"
    echo -e "${YELLOW}  Please edit .env with your database URL${NC}"
else
    echo -e "${GREEN}✓${NC} .env file already exists"
fi

echo ""
echo -e "${YELLOW}=============================================${NC}"
echo -e "${YELLOW}Starting services with Docker Compose...${NC}"
echo -e "${YELLOW}=============================================${NC}"

# Start database services first
docker-compose up -d postgres redis clickhouse

echo "Waiting for services to start..."
sleep 15

# Check PostgreSQL
for i in {1..30}; do
    if docker exec acid-postgres pg_isready -U acid &> /dev/null 2>&1; then
        echo -e "${GREEN}✓ PostgreSQL ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}✗ PostgreSQL failed to start${NC}"
    fi
    sleep 1
done

# Check Redis
for i in {1..10}; do
    if docker exec acid-redis redis-cli ping 2>/dev/null | grep -q PONG; then
        echo -e "${GREEN}✓ Redis ready${NC}"
        break
    fi
    sleep 1
done

# Check ClickHouse
for i in {1..10}; do
    if docker exec acid-clickhouse wget -q -O /dev/null http://localhost:8123/ping &> /dev/null 2>&1; then
        echo -e "${GREEN}✓ ClickHouse ready${NC}"
        break
    fi
    sleep 1
done

echo ""
echo -e "${YELLOW}=============================================${NC}"
echo -e "${YELLOW}Building and starting ACID API...${NC}"
echo -e "${YELLOW}=============================================${NC}"

# Build and start API
docker-compose up -d --build api

# Wait for API to be ready
sleep 5

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🎉 ACID is now running!                                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  ACCESS POINTS:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}Admin Panel:${NC}    http://localhost:8080/admin"
echo -e "  ${GREEN}Home Page:${NC}      http://localhost:8080/"
echo -e "  ${GREEN}Login:${NC}          http://localhost:8080/login"
echo -e "  ${GREEN}API Docs:${NC}      http://localhost:8080/docs"
echo -e "  ${GREEN}Health Check:${NC}  http://localhost:8080/api/health"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  HELPER TOOLS (optional):${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}PGAdmin:${NC}        http://localhost:5050  (admin@acid.local / admin)"
echo -e "  ${GREEN}Adminer:${NC}       http://localhost:8081"
echo ""
echo -e "${YELLOW}To stop: docker-compose down${NC}"
echo -e "${YELLOW}To view logs: docker-compose logs -f${NC}"
echo -e "${YELLOW}To restart: docker-compose restart${NC}"