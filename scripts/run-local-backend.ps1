param(
    [switch]$SkipSeed
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Test-Path (Join-Path $repoRoot ".env"))) {
    Copy-Item (Join-Path $repoRoot ".env.example") (Join-Path $repoRoot ".env")
    Write-Host "Created .env from .env.example"
}

$hostPort = $env:UVICORN_PORT
if (-not $hostPort) { $hostPort = "8080" }

Write-Host "=== SRC local backend ==="
Write-Host "Loading .env and starting uvicorn on 127.0.0.1:$hostPort"
Write-Host "Health: http://127.0.0.1:$hostPort/health"
Write-Host ""

Set-Location (Join-Path $repoRoot "backend\jena_ai")
python -m pip install -q -r requirements.txt

if (-not $SkipSeed) {
    python (Join-Path $repoRoot "scripts\seed_emulator_data.py")
}

python -m uvicorn app.main:app --host 127.0.0.1 --port $hostPort --reload
