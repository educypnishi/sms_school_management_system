@echo off
echo Git Push Script

echo Adding all changes...
git add .

echo Creating commit...
set /p commit_message="Enter commit message (or press Enter for default): "
if "%commit_message%"=="" (
    set commit_message="Update EduCyp application"
)
git commit -m %commit_message%

echo Pushing to GitHub...
git push origin main

echo Done!
pause
