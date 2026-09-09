param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$Region = "asia-northeast3",
    [string]$ServiceName = "src-jena-ai",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-DeployTools.ps1")

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    throw "Google Cloud SDK is not installed. Run .\scripts\install-deploy-tools.ps1 first."
}

$serviceAccount = gcloud run services describe $ServiceName `
    --project $ProjectId `
    --region $Region `
    --format "value(spec.template.spec.serviceAccountName)"

if (-not $serviceAccount) {
    $projectNumber = gcloud projects describe $ProjectId --format "value(projectNumber)"
    $serviceAccount = "$projectNumber-compute@developer.gserviceaccount.com"
}

$roles = @(
    "roles/datastore.user",
    "roles/firebasecloudmessaging.admin"
)

Write-Host "Service account: $serviceAccount"

foreach ($role in $roles) {
  $cmd = @(
        "projects", "add-iam-policy-binding", $ProjectId,
        "--member", "serviceAccount:$serviceAccount",
        "--role", $role
    )
    if ($DryRun) {
        Write-Host "Would run: gcloud $($cmd -join ' ')"
        continue
    }
    gcloud @cmd | Out-Null
    Write-Host "Granted $role"
}

Write-Host "IAM setup complete."
