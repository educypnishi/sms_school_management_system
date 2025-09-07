@echo off
echo Git Push Script

echo Adding all changes...
git add .

echo Creating commit...
set /p commit_message="Enter commit message (or press Enter for default): "
if "%commit_message%"=="" (
    set commit_message="Fix DocumentType conversion errors in document management"
)
git commit -m %commit_message%

echo Pushing to repository...
git push

echo Done!
pause
