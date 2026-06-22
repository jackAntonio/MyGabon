@echo off
REM ============================================================
REM GABON CONNECT - AUTO LAUNCHER
REM Exécute tout automatiquement
REM ============================================================

echo.
echo 🇬🇦 GABON CONNECT - LAUNCHING APP
echo ============================================================
echo.

REM Step 1: Navigate to project
cd /d c:\Users\HP\Downloads\MyGabon
echo ✓ Project directory: %cd%
echo.

REM Step 2: Clean
echo ⏳ Step 1/4: Cleaning build files...
flutter clean
echo ✓ Clean complete
echo.

REM Step 3: Get dependencies
echo ⏳ Step 2/4: Installing dependencies (wait 2-3 minutes)...
flutter pub get
echo ✓ Dependencies installed
echo.

REM Step 4: Build models
echo ⏳ Step 3/4: Generating models (wait 1-2 minutes)...
flutter pub run build_runner build
echo ✓ Models generated
echo.

REM Step 5: Launch
echo ⏳ Step 4/4: Launching app on Chrome...
flutter run -d chrome --target lib/main_modern.dart

echo.
echo ============================================================
echo 🎉 APP LAUNCHED!
echo ============================================================
echo.
pause
