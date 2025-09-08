@echo off
echo Git Push Script

echo Adding all changes...
git add .

echo Creating commit...
git commit -m "Convert visa consultancy app to school management system"

echo Pushing to repository...
git push -u origin main

echo Done!
pause
