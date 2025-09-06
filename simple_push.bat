@echo off
echo Simple GitHub Push

echo Initializing Git repository...
git init

echo Adding all files...
git add .

echo Committing changes...
git commit -m "Initial commit of EduCyp application"

echo Setting up remote repository...
git remote add origin https://github.com/educypnishi/educyp_nishi.git

echo Pushing to GitHub...
git push -f origin master

echo Done!
pause
