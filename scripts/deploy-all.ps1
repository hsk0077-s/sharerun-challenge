param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$Region = "asia-northeast3",
    [string]$ServiceName = "src-jena-ai",
    [Parameter(Mandatory = $true)]
    [string]$PgWebhookSecret,
    [Parameter(Mandatory = $true)]
    [string]$OpsAdminSecret,
    [string]$FirebaseProjectId,
    [string]$ServiceUrl,
    [switch]$SkipFirestore,
    [switch]$SkipCloudRun,
    [switch]$SkipIam,
    [switch]$SkipScheduler,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
. (Join-Path $scriptDir "Resolve-DeployTools.ps1")
$firebaseProject = if ($FirebaseProjectId) { $FirebaseProjectId } else { $ProjectId }

Write-Host "=== Share Run Challenge production deploy ==="
Write-Host "GCP project: $ProjectId"
Write-Host "Firebase project: $firebaseProject"
Write-Host ""

if (-not $SkipFirestore) {
    Write-Host "[1/4] Firestore rules + indexes"
    $firestoreArgs = @{ ProjectId = $firebaseProject }
    if ($DryRun) {
        $firestoreArgs.DryRun = $true
    }
    & "$scriptDir\deploy-firestore.ps1" @firestoreArgs
}

if (-not $SkipCloudRun) {
    Write-Host "[2/4] Cloud Run ($ServiceName)"
    $cloudRunArgs = @{
        ProjectId       = $ProjectId
        Region          = $Region
        ServiceName     = $ServiceName
        PgWebhookSecret = $PgWebhookSecret
        OpsAdminSecret  = $OpsAdminSecret
        DryRun          = $DryRun
    }
    if ($ServiceUrl) {
        $cloudRunArgs.ServiceUrl = $ServiceUrl
    }
    & "$scriptDir\deploy-cloud-run.ps1" @cloudRunArgs

    if (-not $DryRun -and -not $ServiceUrl) {
        $ServiceUrl = gcloud run services describe $ServiceName `
            --project $ProjectId `
            --region $Region `
            --format "value(status.url)"
        Write-Host "Resolved service URL: $ServiceUrl"
    }
}

if (-not $SkipIam) {
    Write-Host "[3/4] Cloud Run IAM (Firestore + FCM)"
    & "$scriptDir\setup-cloud-run-iam.ps1" `
        -ProjectId $ProjectId `
        -Region $Region `
        -ServiceName $ServiceName `
        -DryRun:$DryRun
}

if (-not $SkipScheduler) {
    if (-not $ServiceUrl) {
        throw "ServiceUrl is required for scheduler setup. Pass -ServiceUrl or deploy Cloud Run first."
    }
    Write-Host "[4/4] Cloud Scheduler (purge-deleted daily)"
    & "$scriptDir\setup-cloud-scheduler.ps1" `
        -ProjectId $ProjectId `
        -Region $Region `
        -ServiceUrl $ServiceUrl `
        -OpsAdminSecret $OpsAdminSecret `
        -DryRun:$DryRun
}

Write-Host ""
Write-Host "Deploy pipeline finished."
if ($ServiceUrl) {
    Write-Host "Service URL: $ServiceUrl"
    Write-Host "Flutter build:"
    Write-Host "  flutter build apk --dart-define=JENA_BASE_URL=$ServiceUrl --dart-define=PG_BASE_URL=https://<pg-host>"
}
