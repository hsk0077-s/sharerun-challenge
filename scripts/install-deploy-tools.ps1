param(
    [switch]$SkipGcloud,
    [switch]$SkipFirebase
)

$ErrorActionPreference = "Stop"

if (-not $SkipGcloud -and -not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget is unavailable. Install Google Cloud SDK manually: https://cloud.google.com/sdk/docs/install"
    }
    Write-Host "Installing Google Cloud SDK via winget..."
    winget install --id Google.CloudSDK --exact --accept-package-agreements --accept-source-agreements
    Write-Host "Restart your terminal so gcloud is on PATH, then run: gcloud auth login"
}

if (-not $SkipFirebase -and -not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "Installing Node.js LTS via winget (required for Firebase CLI)..."
            winget install --id OpenJS.NodeJS.LTS --exact --accept-package-agreements --accept-source-agreements
            Write-Host "Restart your terminal so npm is on PATH."
        } else {
            throw "npm is unavailable. Install Node.js, then: npm install -g firebase-tools"
        }
    }

    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "Installing Firebase CLI globally..."
        npm install -g firebase-tools
        Write-Host "Run: firebase login"
    }
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart terminal"
Write-Host "  2. gcloud auth login && gcloud config set project <project-id>"
Write-Host "  3. firebase login && firebase use --add"
Write-Host "  4. .\scripts\deploy-all.ps1 -ProjectId <id> -PgWebhookSecret <s> -OpsAdminSecret <s>"
