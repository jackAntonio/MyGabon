$ErrorActionPreference = "SilentlyContinue"

Write-Host "================================" -ForegroundColor Green
Write-Host "🇬🇦 GABON CONNECT - AUTO SETUP" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# 1. Vérifier Flutter
Write-Host "Step 1/4: Vérification Flutter..." -ForegroundColor Yellow
$flutterCheck = flutter --version 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Flutter trouvé!" -ForegroundColor Green
    Write-Host $flutterCheck
} else {
    Write-Host "❌ Flutter non trouvé. Installation..." -ForegroundColor Red

    # Installer Scoop
    Write-Host "  Installing Scoop..." -ForegroundColor Cyan
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    iwr -useb get.scoop.sh | iex

    # Installer Flutter
    Write-Host "  Installing Flutter..." -ForegroundColor Cyan
    scoop bucket add main
    scoop install flutter

    Write-Host "✅ Flutter installé!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 2/4: Nettoyage du projet..." -ForegroundColor Yellow
cd c:\Users\HP\Downloads\MyGabon
flutter clean
Write-Host "✅ Nettoyage terminé" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3/4: Installation des dépendances (2-3 minutes)..." -ForegroundColor Yellow
flutter pub get
flutter pub run build_runner build
Write-Host "✅ Dépendances installées" -ForegroundColor Green

Write-Host ""
Write-Host "Step 4/4: Lancement de l'app..." -ForegroundColor Yellow
flutter run -d chrome --target lib/main_modern.dart

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "✅ DONE!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
