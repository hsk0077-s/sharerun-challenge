param(
    [string]$Device,
    [switch]$Release,
    [switch]$Debug
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

. (Join-Path $PSScriptRoot "Resolve-DeployTools.ps1")

# Apply mock UI mode to .env
$envPath = Join-Path $repoRoot ".env"
if (-not (Test-Path $envPath)) {
    Copy-Item (Join-Path $repoRoot ".env.example") $envPath
}
$content = Get-Content $envPath -Raw
$content = $content -replace "USE_LOCAL_MOCK_DATA=false", "USE_LOCAL_MOCK_DATA=true"
$content = $content -replace "USE_FIREBASE_EMULATOR=true", "USE_FIREBASE_EMULATOR=false"
$content = $content -replace "ALLOW_ANONYMOUS_BOOTSTRAP=true", "ALLOW_ANONYMOUS_BOOTSTRAP=false"
Set-Content -Path $envPath -Value $content.TrimEnd() -NoNewline
Write-Host "Mock UI mode enabled in .env"

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    $candidates = @(
        (Join-Path $repoRoot "tools\flutter\bin\flutter.bat"),
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:USERPROFILE\develop\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $env:PATH = "$(Split-Path $candidate -Parent);$env:PATH"
            $flutter = Get-Command flutter -ErrorAction SilentlyContinue
            break
        }
    }
}

if (-not $flutter) {
    Write-Host ""
    Write-Host "Flutter SDK not found on PATH."
    Write-Host "Install locally: .\scripts\install-flutter.ps1"
    Write-Host "Or: https://docs.flutter.dev/get-started/install/windows"
    exit 1
}

flutter pub get

# Chrome debug service often times out on OneDrive paths; default to release for chrome.
$useRelease = $Release -or ($Device -eq "chrome" -and -not $Debug)
if ($Device -eq "chrome" -and $useRelease -and -not $Release) {
    Write-Host "Using --release for Chrome (avoids web debug service timeout). Pass -Debug for hot reload."
}

if ($Device) {
    if ($useRelease) {
        flutter run -d $Device --release
    } else {
        flutter run -d $Device
    }
} else {
    flutter devices
    Write-Host ""
    Write-Host "Starting on default device (mock data, dark theme, 5 tabs)..."
    flutter run
}
