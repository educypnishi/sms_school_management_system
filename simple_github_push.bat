@echo off
echo Simple GitHub Push Script

cd /d E:\educyp_01

git init
git add .
git commit -m "Update EduCyp application"
git branch -M main
git remote remove origin
git remote add origin https://github.com/educypnishi/educyp_nishi.git
git push -f origin main

echo Done!
pause
