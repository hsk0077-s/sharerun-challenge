param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceUrl,

    [switch]$RequireReady
)

$ErrorActionPreference = "Stop"

$healthUrl = "$ServiceUrl/health"
$healthResponse = Invoke-RestMethod -Uri $healthUrl -Method Get

if ($healthResponse.status -ne "ok") {
    throw "Liveness check failed at $healthUrl"
}

Write-Host "Liveness OK: $healthUrl"

if ($RequireReady) {
    $readyUrl = "$ServiceUrl/health/ready"
    try {
        $readyResponse = Invoke-RestMethod -Uri $readyUrl -Method Get
    } catch {
        throw "Readiness check failed at $readyUrl. Ensure PG_WEBHOOK_SECRET and OPS_ADMIN_SECRET are set."
    }

    if ($readyResponse.status -ne "ready") {
        throw "Readiness check returned unexpected payload from $readyUrl"
    }

    Write-Host "Readiness OK: $readyUrl"
}
