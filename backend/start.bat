@echo off
cd /d "%~dp0"
echo Starting PetPal AI backend...
.\.venv\Scripts\uvicorn.exe app.main:app --host 127.0.0.1 --port 8000 --reload
