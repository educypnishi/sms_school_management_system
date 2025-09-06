@echo off
echo ===================================================
echo Fixing all issues in EduCyp application...
echo ===================================================

echo Step 1: Removing fluttertoast dependency...
call dart remove_fluttertoast.dart

echo.
echo Step 2: Cleaning project...
call flutter clean

echo.
echo Step 3: Deleting build cache directories...
rmdir /s /q "build" 2>nul
rmdir /s /q ".dart_tool" 2>nul
rmdir /s /q "android\.gradle" 2>nul
rmdir /s /q "android\app\build" 2>nul
rmdir /s /q "android\.idea" 2>nul

echo.
echo Step 4: Deleting Flutter plugin cache...
del /f /q ".flutter-plugins" 2>nul
del /f /q ".flutter-plugins-dependencies" 2>nul

echo.
echo Step 5: Getting dependencies...
call flutter pub get

echo.
echo ===================================================
echo All fixes applied! Try running your app now:
echo.
echo For web: flutter run -d chrome
echo For Android: flutter run
echo ===================================================

pause
