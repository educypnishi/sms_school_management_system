@echo off
echo Setting up new GitHub repository...

echo Initializing git repository...
git init

echo Adding all files...
git add .

echo Creating initial commit...
git commit -m "Initial commit: School Management System"

echo Adding remote repository...
git remote add origin https://github.com/educypnishi/school_management_system.git

echo Pushing to main branch...
git push -u origin main

echo Done!
pause
