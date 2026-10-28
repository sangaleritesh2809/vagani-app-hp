@echo off
title Vargani Pro - Chrome Web App
set "PATH=C:\src\flutter\bin;%PATH%"
cd /d "%~dp0"

echo ======================================================
echo       Starting Vargani Pro (Chrome Web)
echo ======================================================

:: Clean old build directory to avoid OneDrive file locks
rd /s /q "build" 2>nul

call "C:\src\flutter\bin\flutter.bat" run -d chrome
pause
