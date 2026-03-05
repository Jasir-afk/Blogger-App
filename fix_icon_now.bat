@echo off
echo ==============================================
echo       Fixing Flutter App Icon
echo ==============================================
echo.

echo [1/4] Copying the exact flower image you uploaded into your project...
copy "C:\Users\user\.gemini\antigravity\brain\7ebeec41-735f-4dff-8788-23cd64dc9379\media__1772687245590.png" "d:\flutter\Test Project\test_project\assets\images\icon.png" /Y

echo.
echo [2/4] Cleaning project cache...
call flutter clean

echo.
echo [3/4] Downloading packages...
call flutter pub get

echo.
echo [4/4] Generating new app icons (this replaces the B logo)...
call flutter pub run flutter_launcher_icons:main

echo.
echo ==============================================
echo DONE! 
echo If your app is currently open in an emulator or phone, 
echo please close it completely and rebuild/re-run the app.
echo ==============================================
pause
