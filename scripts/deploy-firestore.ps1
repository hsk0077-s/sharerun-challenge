param(
    [string]$ProjectId,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "Resolve-DeployTools.ps1")

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    throw "Firebase CLI is not installed. Run .\scripts\install-deploy-tools.ps1 first."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$deployArgs = @("deploy", "--only", "firestore:rules,firestore:indexes")
if ($ProjectId) {
    $deployArgs += @("--project", $ProjectId)
}

if ($DryRun) {
    Write-Host "Would deploy firestore.rules and firestore.indexes.json from $repoRoot"
    if ($ProjectId) {
        Write-Host "Project: $ProjectId"
    }
    Write-Host "Command: firebase $($deployArgs -join ' ')"
    exit 0
}

firebase @deployArgs
