param(
    [ValidateSet("emulator", "mock")]
    [string]$Mode = "emulator"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Test-Path (Join-Path $repoRoot ".env"))) {
    Copy-Item (Join-Path $repoRoot ".env.example") (Join-Path $repoRoot ".env")
    Write-Host "Created .env from .env.example"
}

$envPath = Join-Path $repoRoot ".env"
$envContent = Get-Content $envPath -Raw

if ($Mode -eq "mock") {
    $envContent = $envContent -replace "USE_LOCAL_MOCK_DATA=false", "USE_LOCAL_MOCK_DATA=true"
    $envContent = $envContent -replace "USE_FIREBASE_EMULATOR=true", "USE_FIREBASE_EMULATOR=false"
    Set-Content -Path $envPath -Value $envContent -NoNewline
    Write-Host "Mode: UI mock (no Firebase). Edit .env to switch back."
    Write-Host ""
    Write-Host "Terminal 1 (optional API): .\scripts\run-local-backend.ps1 -SkipSeed"
    Write-Host "Terminal 2 (Flutter):     flutter pub get && flutter run"
    exit 0
}

# Emulator mode
$envContent = $envContent -replace "USE_LOCAL_MOCK_DATA=true", "USE_LOCAL_MOCK_DATA=false"
$envContent = $envContent -replace "USE_FIREBASE_EMULATOR=false", "USE_FIREBASE_EMULATOR=true"
Set-Content -Path $envPath -Value $envContent -NoNewline

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "Firebase CLI not found."
    Write-Host "Install: npm install -g firebase-tools"
    Write-Host "Or use mock UI mode: .\scripts\start-local-mvp.ps1 -Mode mock"
    exit 1
}

Write-Host "=== SRC local MVP (Firebase Emulator) ==="
Write-Host ""
Write-Host "This script starts:"
Write-Host "  - Firebase Auth + Firestore emulators (UI: http://127.0.0.1:4000)"
Write-Host "  - Seeds demo tournaments / diamond boxes / crews"
Write-Host "  - Local FastAPI backend on http://127.0.0.1:8080"
Write-Host ""
Write-Host "In another terminal:"
Write-Host "  flutter pub get"
Write-Host "  flutter run"
Write-Host ""
Write-Host "Android emulator uses JENA_BASE_URL=http://10.0.2.2:8080 from .env"
Write-Host "iOS simulator / desktop: set FIREBASE_EMULATOR_HOST=127.0.0.1 and JENA_BASE_URL=http://127.0.0.1:8080"
Write-Host ""

firebase emulators:exec `
    --only auth,firestore `
    "cmd /c `"python scripts\seed_emulator_data.py && cd backend\jena_ai && python -m pip install -q -r requirements.txt && python -m uvicorn app.main:app --host 127.0.0.1 --port 8080`""
