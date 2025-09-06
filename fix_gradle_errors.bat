@echo off
echo ===================================================
echo Fixing Gradle build errors...
echo ===================================================

echo Deleting build cache directories...
rmdir /s /q "build"
rmdir /s /q ".dart_tool"
rmdir /s /q "android\.gradle"
rmdir /s /q "android\app\build"
rmdir /s /q "android\.idea"

echo Deleting Flutter plugin cache...
del /f /q ".flutter-plugins"
del /f /q ".flutter-plugins-dependencies"

echo Cleaning Flutter project...
call flutter clean

echo Getting dependencies...
call flutter pub get

echo ===================================================
echo Gradle errors fixed! Try running your app now.
echo ===================================================

pause
