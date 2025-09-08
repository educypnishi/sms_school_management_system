@echo off
echo Pushing to new GitHub repository...

echo Creating GitHub repository...
gh repo create educypnishi/school_management_system --public --source=. --push

echo Done!
pause
