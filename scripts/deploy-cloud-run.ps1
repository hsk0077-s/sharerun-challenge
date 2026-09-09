param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$Region = "asia-northeast3",
    [string]$ServiceName = "src-jena-ai",
    [string]$PgWebhookSecret,
    [string]$OpsAdminSecret,
    [string]$ServiceUrl,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-DeployTools.ps1")

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    throw "Google Cloud SDK is not installed."
}

if (-not $PgWebhookSecret -or -not $OpsAdminSecret) {
    throw "Set -PgWebhookSecret and -OpsAdminSecret before deploying."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot "backend\jena_ai"
$healthScript = Join-Path $PSScriptRoot "check-cloud-run-health.ps1"

$deployArgs = @(
    "run", "deploy", $ServiceName,
    "--project", $ProjectId,
    "--region", $Region,
    "--source", $sourceDir,
    "--allow-unauthenticated",
    "--set-env-vars", "PG_WEBHOOK_SECRET=$PgWebhookSecret,OPS_ADMIN_SECRET=$OpsAdminSecret"
)

if ($DryRun) {
    Write-Host "Would run: gcloud $($deployArgs -join ' ')"
    if ($ServiceUrl) {
        Write-Host "Would run health check against: $ServiceUrl"
    }
    exit 0
}

gcloud @deployArgs

Write-Host ""
Write-Host "After deploy:"
Write-Host "  1. Grant the Cloud Run service account:"
Write-Host "       - Firestore: roles/datastore.user (or tighter)"
Write-Host "       - FCM send: roles/firebasecloudmessaging.admin (or firebase.admin)"
Write-Host "  2. Point the PG webhook to: https://<service-url>/payments/webhook"
Write-Host "  3. Build Flutter with --dart-define=JENA_BASE_URL=https://<service-url>"
Write-Host "  4. Schedule purge batch (daily recommended):"
Write-Host "       POST https://<service-url>/ops/users/purge-deleted"
Write-Host "       Header: X-Ops-Admin-Secret: <OPS_ADMIN_SECRET>"
Write-Host "  5. Ops tournament lifecycle:"
Write-Host "       POST /ops/tournaments/{id}/activate (BEP met -> active + push)"
Write-Host "       POST /ops/tournaments/{id}/cancel-bep-refund (BEP missed -> refund + push)"

if ($ServiceUrl) {
    Write-Host ""
    Write-Host "Running health check..."
    & $healthScript -ServiceUrl $ServiceUrl -RequireReady
}
