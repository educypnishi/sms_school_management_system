@echo off
echo Fixing fluttertoast compatibility issues...

echo Cleaning Flutter project...
call flutter clean

echo Removing .flutter-plugins and .flutter-plugins-dependencies...
if exist .flutter-plugins del .flutter-plugins
if exist .flutter-plugins-dependencies del .flutter-plugins-dependencies

echo Getting dependencies...
call flutter pub get

echo Running app on web platform...
call flutter run -d chrome

echo Done!
