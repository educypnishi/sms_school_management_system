@echo off
echo ===================================================
echo GitHub Push Script for EduCyp Project
echo ===================================================

REM Check if Git is installed
where git >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Git is not installed or not in PATH.
    echo Please install Git from https://git-scm.com/downloads
    pause
    exit /b 1
)

echo Git is installed. Proceeding with push...

REM Initialize Git repository if not already initialized
if not exist .git (
    echo Initializing Git repository...
    git init
) else (
    echo Git repository already initialized.
)

REM Configure Git if needed
echo Configuring Git...
git config --local user.name "EduCyp"
git config --local user.email "educyp@example.com"

REM Check if remote origin exists
git remote -v | findstr origin >nul
if %ERRORLEVEL% NEQ 0 (
    echo Adding GitHub remote repository...
    git remote add origin https://github.com/educypnishi/educyp_nishi.git
) else (
    echo Remote repository already set. Updating...
    git remote set-url origin https://github.com/educypnishi/educyp_nishi.git
)

REM Add all files
echo Adding all files to Git...
git add .

REM Commit changes
echo Committing changes...
set /p commit_message=Enter commit message (default: "Update EduCyp application"): 
if "%commit_message%"=="" set commit_message=Update EduCyp application
git commit -m "%commit_message%"

REM Create or switch to main branch
echo Setting up main branch...
git branch -M main

REM Push to GitHub
echo Pushing to GitHub...
echo You may be prompted for your GitHub username and password/token
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo ===================================================
    echo Push successful! Your code is now on GitHub.
    echo Repository: https://github.com/educypnishi/educyp_nishi.git
    echo ===================================================
) else (
    echo ===================================================
    echo Push failed. Please check your credentials and try again.
    echo If you're using a password, you may need to use a personal access token instead.
    echo Create one at: https://github.com/settings/tokens
    echo ===================================================
)

pause
