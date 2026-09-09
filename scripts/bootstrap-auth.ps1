param(
    [string]$ProjectId
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-DeployTools.ps1")

Write-Host "=== GCP / Firebase login ==="
Write-Host ""

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    throw "gcloud not found. Run .\scripts\install-deploy-tools.ps1 first."
}

Write-Host "[1/3] gcloud auth login (browser will open)"
gcloud auth login

if ($ProjectId) {
    Write-Host "[2/3] Setting project: $ProjectId"
    gcloud config set project $ProjectId
} else {
    Write-Host "[2/3] Select default project"
    gcloud projects list
    $selected = Read-Host "Enter GCP project ID"
    if ($selected) {
        gcloud config set project $selected
    }
}

if (Get-Command firebase -ErrorAction SilentlyContinue) {
    Write-Host "[3/3] firebase login"
    firebase login
    if ($ProjectId) {
        firebase use $ProjectId
    } elseif ($selected) {
        firebase use $selected
    } else {
        firebase use --add
    }
} else {
    Write-Host "[SKIP] Firebase CLI not installed yet."
    Write-Host "       Approve Node.js UAC prompt, then run:"
    Write-Host "       npm install -g firebase-tools"
    Write-Host "       firebase login"
}

Write-Host ""
Write-Host "Auth complete. Verify with:"
Write-Host "  .\scripts\verify-deploy-ready.ps1"
Write-Host ""
Write-Host "Then deploy:"
Write-Host "  .\scripts\deploy-all.ps1 -ProjectId <id> -PgWebhookSecret <s> -OpsAdminSecret <s>"
