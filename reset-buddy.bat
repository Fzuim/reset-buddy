@echo off
setlocal enabledelayedexpansion

:: reset-buddy.bat — Reset Claude Code companion by regenerating userID and clearing companion data.
:: New userID follows Claude's rule: randomBytes(32).toString('hex') → 64 hex chars.
::
:: Usage: reset-buddy.bat [--dry-run]

set "CONFIG_FILE=%USERPROFILE%\.claude.json"

if not exist "%CONFIG_FILE%" (
    echo Error: %CONFIG_FILE% not found
    exit /b 1
)

set "DRY_RUN=false"
if "%~1"=="--dry-run" (
    set "DRY_RUN=true"
    echo [dry-run] No changes will be written.
)

:: Validate current file is valid JSON
python -c "import json, sys; json.load(open(sys.argv[1]))" "%CONFIG_FILE%" 2>nul
if errorlevel 1 (
    echo Error: %CONFIG_FILE% is not valid JSON
    exit /b 1
)

:: Show current state
for /f "delims=" %%i in ('python -c "import json; d=json.load(open(r'%CONFIG_FILE%')); print(d.get('userID', '(not found)'))"') do set "OLD_USER_ID=%%i"
for /f "delims=" %%i in ('python -c "import json; d=json.load(open(r'%CONFIG_FILE%')); c=d.get('companion'); print(json.dumps(c, ensure_ascii=False) if c else '(none)')"') do set "OLD_COMPANION=%%i"

echo Current state:
echo   userID:    %OLD_USER_ID%
echo   companion: %OLD_COMPANION%

:: Generate new userID: same as Node's crypto.randomBytes(32).toString('hex')
for /f "delims=" %%i in ('python -c "import secrets; print(secrets.token_hex(32))"') do set "NEW_USER_ID=%%i"

echo.
echo New userID: %NEW_USER_ID%

if "%DRY_RUN%"=="true" (
    echo.
    echo [dry-run] Would write:
    echo   userID    → %NEW_USER_ID%
    echo   companion → (removed)
    exit /b 0
)

:: Backup original
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do set "DATEPART=%%a%%b%%c"
for /f "tokens=1-3 delims=:." %%a in ('echo %time%') do set "TIMEPART=%%a%%b%%c"
set "BACKUP_FILE=%USERPROFILE%\.claude.json.buddy-backup.%DATEPART%%TIMEPART%"

copy "%CONFIG_FILE%" "%BACKUP_FILE%" >nul
echo.
echo Backup saved: %BACKUP_FILE%

:: Update JSON: set new userID, remove companion
python -c "import json, sys; data=json.load(open(sys.argv[1])); data['userID']=sys.argv[2]; data.pop('companion', None); f=open(sys.argv[1],'w'); json.dump(data, f, indent=2, ensure_ascii=False); f.write('\n'); f.close()" "%CONFIG_FILE%" "%NEW_USER_ID%"

:: Verify
for /f "delims=" %%i in ('python -c "import json; d=json.load(open(r'%CONFIG_FILE%')); print(d.get('userID'))"') do set "VERIFY_UID=%%i"
for /f "delims=" %%i in ('python -c "import json; d=json.load(open(r'%CONFIG_FILE%')); print(d.get('companion', '(none)'))"') do set "VERIFY_COMP=%%i"

echo.
echo Done. Verified:
echo   userID:    %VERIFY_UID%
echo   companion: %VERIFY_COMP%
echo.
echo Restart Claude Code and run /buddy to hatch a new companion.

endlocal
