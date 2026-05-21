function Set-PSNowTestEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [string]$ProjectName = 'PSNow'
    )

    $stagingRoot = Join-Path $RepoRoot 'Staging'
    $stagedModuleRoot = Join-Path $stagingRoot $ProjectName
    $stagedManifestPath = Join-Path $stagedModuleRoot ("{0}.psd1" -f $ProjectName)

    if (-not (Test-Path -Path $stagedManifestPath -PathType Leaf)) {
        throw "Staged module manifest not found: $stagedManifestPath"
    }

    # Match the BuildHelpers-style environment expected by Pester tests.
    $env:BHProjectPath = $RepoRoot
    $env:BHProjectName = $ProjectName
    $env:BHPSModulePath = $stagingRoot
    $env:BHModulePath = $stagedModuleRoot
    $env:BHPSModuleManifest = $stagedManifestPath

    Get-Module -Name $ProjectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module -Name $stagedManifestPath -Force -ErrorAction Stop

    return [pscustomobject]@{
        ProjectName       = $ProjectName
        StagingRoot       = $stagingRoot
        StagedModuleRoot  = $stagedModuleRoot
        StagedManifest    = $stagedManifestPath
    }
}
