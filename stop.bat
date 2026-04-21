@echo off
chcp 65001 >nul 2>&1
title ACID Server Stop

echo ================================================================================
echo ACID - Stopping All Services...
echo ================================================================================

echo.
echo [1/2] Stopping Docker containers...
docker-compose down 2>nul

echo [2/2] Cleaning up...
echo.

echo ================================================================================
echo ALL SERVICES STOPPED
echo ================================================================================

pause