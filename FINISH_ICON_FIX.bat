@echo off
setlocal

:: Get the path of the current directory
set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

echo ==============================================
echo       Final Icon Fixer
echo ==============================================
echo.

:: 1. Copy the flower image into the project as icon.png
:: Using the absolute path provided in the previous interaction
echo [1/4] Copying flower image...
copy "C:\Users\user\.gemini\antigravity\brain\7ebeec41-735f-4dff-8788-23cd64dc9379\media__1772687245590.png" "assets\images\icon.png" /Y
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to copy image. Please save it manually as assets/images/icon.png
) else (
    echo [SUCCESS] Image copied.
)

:: 2. Create a copy of icon.png as logo.png to fix the splash screen immediately
echo [2/4] Replacing old logo...
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
echo Please RESTART your app completely.
echo ==============================================
pause
