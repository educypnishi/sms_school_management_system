@echo off
echo ===================================================
echo Fixing fluttertoast compatibility issues...
echo ===================================================

echo Running fluttertoast removal script...
call dart remove_fluttertoast.dart

echo.
echo ===================================================
echo Cleaning Flutter project...
echo ===================================================
call flutter clean

echo.
echo ===================================================
echo Getting dependencies...
echo ===================================================
call flutter pub get

echo.
echo ===================================================
echo Running app on web platform...
echo ===================================================
echo To run the app on web, use: flutter run -d chrome
echo To run the app on Android, use: flutter run -d [device-id]
echo.
echo Fix complete! Your app should now build without fluttertoast errors.
echo ===================================================

pause
