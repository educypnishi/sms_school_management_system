@echo off
echo Git Push Script

echo Adding all changes...
git add .

echo Creating commit...
git commit -m "Add University Comparison Tool feature"

echo Pushing to repository...
git push

echo Done!
pause
