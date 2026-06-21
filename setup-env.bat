@echo off
REM Setup environment variables for Node.js and Firebase
REM Run this once at startup

echo Setting up Node.js and Firebase CLI paths...

REM Add Node.js to PATH
set PATH=C:\Program Files\nodejs;%PATH%
set PATH=C:\Users\HP\AppData\Roaming\npm;%PATH%

echo ✅ Environment configured!
echo.
echo Available commands:
echo   - node --version
echo   - npm --version
echo   - firebase --version
echo   - firebase login
echo.
echo Type 'cmd' to start a new terminal with paths configured
pause
