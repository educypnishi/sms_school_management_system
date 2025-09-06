@echo off
echo Starting GitHub push process...

echo Initializing Git repository...
git init

echo Configuring Git...
git config --global user.name "EduCyp"
git config --global user.email "educyp@example.com"

echo Adding remote repository...
git remote add origin https://github.com/educypnishi/educyp.git

echo Adding all files...
git add .

echo Committing changes...
git commit -m "Initial commit of EduCyp application"

echo Creating main branch...
git branch -M main

echo Pushing to GitHub...
git push -u origin main

echo Done!
pause
