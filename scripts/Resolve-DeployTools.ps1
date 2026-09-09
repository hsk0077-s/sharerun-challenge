$ErrorActionPreference = "Stop"

function Add-DeployToolPaths {
    $paths = @(
        (Join-Path $env:LOCALAPPDATA "Google\Cloud SDK\google-cloud-sdk\bin"),
        (Join-Path $env:ProgramFiles "Google\Cloud SDK\google-cloud-sdk\bin"),
        "${env:ProgramFiles(x86)}\Google\Cloud SDK\google-cloud-sdk\bin"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            if ($env:PATH -notlike "*$path*") {
                $env:PATH = "$path;$env:PATH"
            }
        }
    }
}

function Get-GcloudCommand {
    Add-DeployToolPaths
    $command = Get-Command gcloud -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    throw "Google Cloud SDK is not installed. Run .\scripts\install-deploy-tools.ps1 first."
}

function Get-FirebaseCommand {
    $command = Get-Command firebase -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    throw "Firebase CLI is not installed. Run .\scripts\install-deploy-tools.ps1 first."
}

Add-DeployToolPaths
