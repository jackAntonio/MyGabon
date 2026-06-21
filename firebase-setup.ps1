# Firebase Setup Script for GabonConnect
# Usage: .\firebase-setup.ps1

Write-Host "🔥 Firebase Setup for GabonConnect" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

# Setup PATH
$env:Path = "C:\Program Files\nodejs;C:\Users\HP\AppData\Roaming\npm;$env:Path"

# Verify installations
Write-Host "Checking installations..." -ForegroundColor Cyan
Write-Host ""

# Check Node
Write-Host "Node.js: " -ForegroundColor Yellow -NoNewline
node --version

# Check npm
Write-Host "npm: " -ForegroundColor Yellow -NoNewline
npm --version

# Check Firebase CLI
Write-Host "Firebase CLI: " -ForegroundColor Yellow -NoNewline
& "C:\Users\HP\AppData\Roaming\npm\firebase.cmd" --version

Write-Host ""
Write-Host "✅ All tools ready!" -ForegroundColor Green
Write-Host ""

# Menu
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Login to Firebase:"
Write-Host "   firebase login" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Initialize Firebase in project:"
Write-Host "   firebase init" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Deploy:"
Write-Host "   firebase deploy" -ForegroundColor Yellow
Write-Host ""
Write-Host "For help, run:" -ForegroundColor Cyan
Write-Host "   firebase --help" -ForegroundColor Yellow
