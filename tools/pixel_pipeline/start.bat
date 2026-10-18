@echo off
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
 echo Execute primeiro powershell -ExecutionPolicy Bypass -File install.ps1
 pause
 exit /b 1
)
echo Abra http://127.0.0.1:8877
".venv\Scripts\python.exe" app.py
