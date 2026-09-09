param(
    [string]$ProjectId
)

$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "Resolve-DeployTools.ps1")
$ready = $true

function Test-Tool {
    param(
        [string]$Name,
        [string]$InstallHint
    )

    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        Write-Host "[OK] $Name"
        return $true
    }

    Write-Host "[MISSING] $Name - $InstallHint"
    return $false
}

Write-Host "=== Deploy readiness check ==="

if (-not (Test-Tool "gcloud" "Run .\scripts\install-deploy-tools.ps1 or install Google Cloud SDK")) {
    $ready = $false
}
if (-not (Test-Tool "firebase" "Run .\scripts\install-deploy-tools.ps1 or npm install -g firebase-tools")) {
    $ready = $false
}
if (-not (Test-Tool "python" "Install Python 3.12+")) {
    $ready = $false
}

if (Get-Command gcloud -ErrorAction SilentlyContinue) {
    $account = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
    if ($account) {
        Write-Host "[OK] gcloud auth: $account"
    } else {
        Write-Host "[MISSING] gcloud auth - run: gcloud auth login"
        $ready = $false
    }

    $project = gcloud config get-value project 2>$null
    if ($project -and $project -ne "(unset)") {
        Write-Host "[OK] gcloud project: $project"
    } elseif ($ProjectId) {
        Write-Host "[INFO] Will use -ProjectId $ProjectId"
    } else {
        Write-Host "[MISSING] gcloud project - run: gcloud config set project <id>"
        $ready = $false
    }
}

if (Get-Command firebase -ErrorAction SilentlyContinue) {
    $firebaseProject = firebase use 2>&1 | Select-String "active project" -SimpleMatch
    if ($firebaseProject) {
        Write-Host "[OK] firebase: $firebaseProject"
    } else {
        Write-Host "[WARN] firebase project not set - run: firebase use --add"
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if (Test-Path (Join-Path $repoRoot "firestore.rules")) {
    Write-Host "[OK] firestore.rules"
} else {
    Write-Host "[MISSING] firestore.rules"
    $ready = $false
}

if ($ready) {
    Write-Host ""
    Write-Host "Ready. Example:"
    Write-Host "  .\scripts\deploy-all.ps1 -ProjectId <id> -PgWebhookSecret <s> -OpsAdminSecret <s>"
    exit 0
}

Write-Host ""
Write-Host "Not ready. Install tools first:"
Write-Host "  .\scripts\install-deploy-tools.ps1"
exit 1
