param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [Parameter(Mandatory = $true)]
    [string]$ServiceUrl,

    [Parameter(Mandatory = $true)]
    [string]$OpsAdminSecret,

    [string]$Region = "asia-northeast3",
    [string]$JobName = "src-purge-deleted-accounts-daily",
    [string]$Schedule = "0 3 * * *",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-DeployTools.ps1")

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    throw "Google Cloud SDK is not installed. Run .\scripts\install-deploy-tools.ps1 first."
}

$serviceUrl = $ServiceUrl.TrimEnd("/")
$uri = "$serviceUrl/ops/users/purge-deleted"

$existing = gcloud scheduler jobs describe $JobName `
    --project $ProjectId `
    --location $Region `
    2>$null

if ($LASTEXITCODE -eq 0) {
    $args = @(
        "scheduler", "jobs", "update", "http", $JobName,
        "--project", $ProjectId,
        "--location", $Region,
        "--schedule", $Schedule,
        "--uri", $uri,
        "--http-method", "POST",
        "--update-headers", "X-Ops-Admin-Secret=$OpsAdminSecret"
    )
    $action = "update"
} else {
    $args = @(
        "scheduler", "jobs", "create", "http", $JobName,
        "--project", $ProjectId,
        "--location", $Region,
        "--schedule", $Schedule,
        "--uri", $uri,
        "--http-method", "POST",
        "--headers", "X-Ops-Admin-Secret=$OpsAdminSecret"
    )
    $action = "create"
}

if ($DryRun) {
    Write-Host "Would $action scheduler job: gcloud $($args -join ' ')"
    exit 0
}

gcloud @args
Write-Host "Cloud Scheduler job '$JobName' ${action}d ($Schedule -> $uri)"
