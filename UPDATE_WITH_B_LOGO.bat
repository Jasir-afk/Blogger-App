@echo off
setlocal

:: Path of the project
set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

echo ==============================================
echo       NEW "B" LOGO ICON FIXER
echo ==============================================
echo.

:: 1. Copy the "B" logo into the project as icon.png
:: The path of the image you just sent is media__1772690539358.png
echo [1/4] Copying NEW "B" Logo...
copy "C:\Users\user\.gemini\antigravity\brain\7ebeec41-735f-4dff-8788-23cd64dc9379\media__1772690539358.png" "assets\images\icon.png" /Y

:: 2. Also replace logo.png for internal screens (splash, auth)
echo [2/4] Updating logo.png for splash screens...
copy "assets\images\icon.png" "assets\images\logo.png" /Y

echo.
echo [3/4] Cleaning Flutter cache...
call flutter clean

echo.
echo [4/4] Generating Launcher Icons...
call flutter pub get
call flutter pub run flutter_launcher_icons

echo.
echo ==============================================
echo ALL DONE! 
echo Please RESTART your app completely for changes to show.
echo ==============================================
pause
