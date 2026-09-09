param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$toolsDir = Join-Path $repoRoot "tools"
$flutterRoot = Join-Path $toolsDir "flutter"
$flutterBat = Join-Path $flutterRoot "bin\flutter.bat"

if ((Test-Path $flutterBat) -and -not $Force) {
    Write-Host "Flutter SDK already installed at $flutterRoot"
    exit 0
}

Write-Host "Fetching latest stable Flutter release metadata..."
$releases = Invoke-RestMethod "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$stableHash = $releases.current_release.stable
$stable = $releases.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1
$url = "https://storage.googleapis.com/flutter_infra_release/releases/$($stable.archive)"
$zip = Join-Path $env:TEMP "flutter_windows_stable.zip"

Write-Host "Downloading Flutter ($($stable.version))..."
Write-Host $url
$zip = Join-Path $env:TEMP "flutter_windows_stable.zip"
if (Test-Path $zip) {
    Remove-Item $zip -Force
}
curl.exe -L --retry 5 --fail --output $zip $url
if ($LASTEXITCODE -ne 0) {
    throw "Flutter download failed (curl exit $LASTEXITCODE)"
}

New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
if (Test-Path $flutterRoot) {
    Remove-Item $flutterRoot -Recurse -Force
}

Write-Host "Extracting to $flutterRoot ..."
Expand-Archive -Path $zip -DestinationPath $toolsDir -Force
Remove-Item $zip -Force

if (-not (Test-Path $flutterBat)) {
    throw "Flutter install failed: $flutterBat not found"
}

$env:PATH = "$(Join-Path $flutterRoot 'bin');$env:PATH"
Write-Host "Running flutter doctor (first run may take a few minutes)..."
& $flutterBat doctor

Write-Host ""
Write-Host "Flutter installed: $flutterRoot"
Write-Host "Next: .\scripts\run-mock-ui.ps1"
