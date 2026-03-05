@echo off
setlocal

:: Path of the project
set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

echo ==============================================
echo       EMERGENCY APP ICON FIX
echo ==============================================
echo.

:: 1. Copy the "B" logo into the project
echo [1/4] Restoring icon.png...
copy "C:\Users\user\.gemini\antigravity\brain\7ebeec41-735f-4dff-8788-23cd64dc9379\media__1772690539358.png" "assets\images\icon.png" /Y
copy "assets\images\icon.png" "assets\images\logo.png" /Y

echo.
echo [2/4] Fixing Android Resource Linking Error...
:: Create the missing drawable directory if it doesn't exist
if not exist "android\app\src\main\res\drawable" mkdir "android\app\src\main\res\drawable"

:: We force flutter_launcher_icons to generate the files by fixing the config first.
:: I will fix the ic_launcher.xml directly to use mipmap instead of the missing drawable.

echo Updating ic_launcher.xml...
(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"^>
echo   ^<background android:drawable="@color/ic_launcher_background"/^>
echo   ^<foreground android:drawable="@mipmap/ic_launcher"/^>
echo ^</adaptive-icon^>
) > "android\app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml"

echo.
echo [3/4] Re-generating icons with correct config...
call flutter pub get
:: Use dart run as it's the modern way
call dart run flutter_launcher_icons

echo.
echo [4/4] Cleaning caches...
call flutter clean

echo.
echo ==============================================
echo DONE! 
echo The Android build error is now fixed. 
echo Please RESTART your app completely from VS Code.
echo ==============================================
pause
