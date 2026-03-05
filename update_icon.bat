@echo off
echo ==============================================
echo       Flutter App Icon Updater
echo ==============================================
echo.
if not exist "assets\images\icon.png" (
    echo [ERROR] icon.png not found in assets/images/
    echo Please save your new icon as 'icon.png' in assets/images/ first.
    pause
    exit /b
)

echo [1/3] Cleaning project...
call flutter clean
echo.
echo [2/3] Getting packages...
call flutter pub get
echo.
echo [3/3] Generating app icons...
call flutter pub run flutter_launcher_icons:main
echo.
echo ==============================================
echo DONE! Please restart your emulator or rebuild the app.
echo ==============================================
pause
