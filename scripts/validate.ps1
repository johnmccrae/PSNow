[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $env:BHProjectName) {
    $env:BHProjectName = 'PSNow'
}
if (-not $env:BHModulePath) {
    $stagedModulePath = Join-Path $repoRoot ("Staging{0}{1}" -f [System.IO.Path]::DirectorySeparatorChar, $env:BHProjectName)
    $env:BHModulePath = if (Test-Path -Path $stagedModulePath) { $stagedModulePath } else { $repoRoot }
}

function Invoke-ValidationStep {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & pwsh -NoProfile -NonInteractive -File ./Build/build.ps1 @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Validation step failed: ./Build/build.ps1 $($Arguments -join ' ')"
    }
}

Write-Output '[validate] resolving dependencies + init'
Invoke-ValidationStep -Arguments @('-ResolveDependency', '-TaskList', 'init')

Write-Output '[validate] staging module'
Invoke-ValidationStep -Arguments @('-TaskList', 'stage')

Write-Output '[validate] running analyzer'
Invoke-ValidationStep -Arguments @('-TaskList', 'analyze')

Write-Output '[validate] running tests'
Invoke-ValidationStep -Arguments @('-TaskList', 'test')

Write-Output '[validate] completed'