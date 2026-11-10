@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ============================================================================
echo   KMUTT Greenhouse Digital Twin - Web Portal Publisher (GitHub Pages)
echo ============================================================================

:: 1. Locate a real Python interpreter (avoiding Windows Store zero-byte stub)
set "PY_CMD="
python --version >nul 2>nul && set "PY_CMD=python"
if not defined PY_CMD (
    py --version >nul 2>nul && set "PY_CMD=py"
)
if not defined PY_CMD (
    if exist "D:\Download_chrome\Modelica\tools\msys\ucrt64\bin\python.exe" (
        set "PY_CMD=D:\Download_chrome\Modelica\tools\msys\ucrt64\bin\python.exe"
    )
)

if exist "scripts\sync_portal_navigation.py" (
    if defined PY_CMD (
        echo [1/3] Synchronizing portal navigation and verifying links...
        "%PY_CMD%" scripts\sync_portal_navigation.py
        "%PY_CMD%" scripts\verify_web_portal.py
        if errorlevel 1 (
            echo [ERROR] Portal verification failed. Please check the error above.
            pause
            exit /b 1
        )
    ) else (
        echo [1/3] Python not found; skipping sync script.
    )
) else (
    echo [1/3] Local scripts\ folder not present in this clone; skipping sync step.
)

:: 2. Verify Git is installed (with standard Windows & MSYS2 fallback paths)
where git >nul 2>nul
if errorlevel 1 (
    if exist "%ProgramFiles%\Git\cmd\git.exe" (
        set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
    ) else if exist "C:\Program Files\Git\cmd\git.exe" (
        set "PATH=C:\Program Files\Git\cmd;%PATH%"
    ) else if exist "D:\Download_chrome\Modelica\tools\msys\usr\bin\git.exe" (
        set "PATH=D:\Download_chrome\Modelica\tools\msys\usr\bin;%PATH%"
    )
)

where git >nul 2>nul
if errorlevel 1 (
    echo.
    echo [ERROR] Git is not installed or not in your system PATH yet.
    echo To install Git on Windows, run this in PowerShell:
    echo   winget install --id Git.Git -e --source winget
    echo.
    pause
    exit /b 1
)

:: 3. Stage web files, commit, and push to GitHub
echo [2/3] Staging website files (index.html, reports/, presentations/)...
git add .gitignore .nojekyll index.html publish_web.bat reports presentations

set "COMMIT_MSG=%~1"
if "%COMMIT_MSG%"=="" set "COMMIT_MSG=Update KMUTT Greenhouse reports and presentations (%DATE% %TIME%)"

git diff --cached --quiet
if errorlevel 1 (
    echo [3/3] Committing changes...
    git commit -m "%COMMIT_MSG%"
) else (
    echo [3/3] No new local file changes to commit.
)

:: Check if origin remote is configured properly before pushing
set "REMOTE_URL="
for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "REMOTE_URL=%%R"
if not defined REMOTE_URL (
    echo.
    echo [NOTICE] Local commit saved, but Git remote 'origin' is not set yet.
    echo Run: git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
    echo Then run publish_web.bat again.
    pause
    exit /b 0
)
echo "%REMOTE_URL%" | findstr /i "<your-username>" >nul
if not errorlevel 1 (
    echo.
    echo [NOTICE] Local commit saved, but 'origin' still points to placeholder: %REMOTE_URL%
    echo Run: git remote set-url origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
    echo Then run publish_web.bat again.
    pause
    exit /b 0
)

echo Pushing to GitHub (%REMOTE_URL%)...
git push -u origin main
if errorlevel 1 (
    echo [ERROR] git push failed. Please check your GitHub repository URL and credentials.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Website updated! GitHub Pages will refresh within 30-60 seconds.
echo ============================================================================
pause
