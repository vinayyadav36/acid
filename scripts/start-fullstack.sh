#!/usr/bin/env bash
# =============================================================================
#  L.S.D — Full-stack start (backend + open frontend)
#  BACKEND + FRONTEND entry-point
# =============================================================================
#  Usage:
#    chmod +x scripts/start-fullstack.sh
#    ./scripts/start-fullstack.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "┌──────────────────────────────────────────────────────────┐"
echo "│   ◆ BACKEND + FRONTEND  L.S.D Full-Stack Launcher        │"
echo "└──────────────────────────────────────────────────────────┘"
echo ""

# Start Docker dependencies (best-effort)
if command -v docker >/dev/null 2>&1; then
    if docker compose version >/dev/null 2>&1; then
        echo "[INFO] Starting Docker dependencies with docker compose ..."
        (cd "$SCRIPT_DIR/.." && docker compose up -d) || echo "[WARN] docker compose failed, continuing with local startup"
    elif command -v docker-compose >/dev/null 2>&1; then
        echo "[INFO] Starting Docker dependencies with docker-compose ..."
        (cd "$SCRIPT_DIR/.." && docker-compose up -d) || echo "[WARN] docker-compose failed, continuing with local startup"
    fi
fi

# Start backend in background using the hardened start script
bash "$SCRIPT_DIR/start-backend.sh" --daemon

# Give backend a moment to bind the port
sleep 2

# Open frontend
bash "$SCRIPT_DIR/start-frontend.sh"
