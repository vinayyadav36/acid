@echo off
chcp 65001 >nul 2>&1
title ACID Server Startup

echo ================================================================================
echo ACID - Advanced Database Interface System
echo Starting All Services...
echo ================================================================================
echo.

REM Check if Docker is available
echo [1/5] Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not running
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo Docker found

REM Stop any existing containers
echo.
echo [2/5] Cleaning up existing containers...
docker-compose down 2>nul

REM Build and start all services
echo.
echo [3/5] Building and starting Docker services...
docker-compose up -d --build

REM Wait for services to be healthy
echo.
echo [4/5] Waiting for services to be ready...
echo.

REM Wait for PostgreSQL
echo - Waiting for PostgreSQL...
:wait_pg
docker exec acid-postgres pg_isready -U acid >nul 2>&1
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto wait_pg
)
echo   PostgreSQL OK

REM Wait for Redis
echo - Waiting for Redis...
docker exec acid-redis redis-cli ping >nul 2>&1
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto wait_pg
)
echo   Redis OK

REM Wait for API to respond
echo - Waiting for ACID API...
:wait_api
curl -s http://localhost:8080/api/health >nul 2>&1
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto wait_api
)
echo   ACID API OK

echo.
echo ================================================================================
echo ALL SERVICES STARTED SUCCESSFULLY!
echo ================================================================================
echo.
echo Access the application at:
echo   - Main Page:      http://localhost:8080/
echo   - Login:          http://localhost:8080/login
echo   - Register:       http://localhost:8080/register
echo   - Dashboard:      http://localhost:8080/dashboard
echo   - Admin Panel:    http://localhost:8080/admin
echo   - API Health:     http://localhost:8080/api/health
echo   - Swagger:       http://localhost:8080/swagger.yaml
echo.
echo Management UIs:
echo   - PGAdmin:       http://localhost:5050 (admin@acid.local / admin)
echo   - Adminer:       http://localhost:8081
echo.
echo ================================================================================
echo Server is running! Press Ctrl+C to stop all services.
echo ================================================================================

REM Keep showing status and wait for interrupt
echo.
:running
echo [STATUS] All services running - %date% %time%
timeout /t 30 /nobreak >nul
goto running