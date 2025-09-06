@echo off
echo ===================================================
echo Verifying Git Account Status
echo ===================================================

REM Check if Git is installed
where git >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Git is not installed or not in PATH.
    echo Please install Git from https://git-scm.com/downloads
    pause
    exit /b 1
)

echo Git is installed. Checking configuration...

REM Check Git configuration
echo.
echo Current Git Configuration:
git config --list

REM Check if user.name and user.email are set
git config user.name >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo WARNING: Git username is not set.
    set /p git_username=Enter your Git username: 
    git config --global user.name "%git_username%"
)

git config user.email >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo WARNING: Git email is not set.
    set /p git_email=Enter your Git email: 
    git config --global user.email "%git_email%"
)

echo.
echo Updated Git Configuration:
git config --list

REM Test connection to GitHub
echo.
echo Testing connection to GitHub...
git ls-remote https://github.com/educypnishi/educyp_nishi.git >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: Connection to GitHub repository verified.
    echo Repository: https://github.com/educypnishi/educyp_nishi.git
) else (
    echo WARNING: Could not connect to GitHub repository.
    echo This could be due to:
    echo  - Repository does not exist
    echo  - No internet connection
    echo  - Authentication issues
    echo.
    echo You will be prompted for credentials when pushing.
)

echo.
echo ===================================================
echo Git Account Verification Complete
echo ===================================================

pause
