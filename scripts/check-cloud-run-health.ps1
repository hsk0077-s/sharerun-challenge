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
        throw "Readiness check failed at $readyUrl. Ensure OPS_ADMIN_SECRET is set (and PG_WEBHOOK_SECRET when PAYMENTS_ENABLED=true)."
    }

    if ($readyResponse.status -ne "ready") {
        throw "Readiness check returned unexpected payload from $readyUrl"
    }

    Write-Host "Readiness OK: $readyUrl"
}
