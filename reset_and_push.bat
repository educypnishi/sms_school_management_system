@echo off
echo Resetting Git credentials and pushing to GitHub...

echo Clearing Git credentials...
git config --system --unset credential.helper
git config --global --unset credential.helper
git config --local --unset credential.helper

echo Initializing Git repository...
git init

echo Setting temporary Git credentials...
git config --local user.name "EduCypTemp"
git config --local user.email "temp@example.com"

echo Removing any existing remote repositories...
git remote remove origin

echo Adding remote repository with credentials in URL...
git remote add origin https://github.com/educypnishi/educyp_nishi.git

echo Adding all files...
git add .

echo Committing changes...
git commit -m "Initial commit of EduCyp application"

echo Creating main branch...
git branch -M main

echo Pushing to GitHub...
echo You will be prompted for your GitHub username and password/token
git push -u origin main

echo Done!
pause
