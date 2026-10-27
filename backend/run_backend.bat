@echo off
title Vargani Pro - FastAPI Server
cd /d "%~dp0"
echo ======================================================
echo       Starting Vargani Pro FastAPI & Supabase Server
echo ======================================================
echo Server: http://127.0.0.1:8000
echo Swagger API Docs: http://127.0.0.1:8000/docs
echo.
python main.py
pause
