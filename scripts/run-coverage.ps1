[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location -Path $repoRoot

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    Write-Output "[coverage] $Name"
    & $ScriptBlock
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $Name"
    }
}

Invoke-Step -Name 'staging module for test consistency' -ScriptBlock {
    pwsh -NoProfile -NonInteractive -File ./Build/build.ps1 -TaskList stage
}

. "$PSScriptRoot/Set-PSNowTestEnvironment.ps1"
Set-PSNowTestEnvironment -RepoRoot $repoRoot -ProjectName 'PSNow'

$coveragePaths = @(
    './Staging/PSNow/Public/*.ps1'
    './Staging/PSNow/Private/*.ps1'
    './Staging/PSNow/PSNow.psm1'
)

$outputDirectory = Join-Path $repoRoot 'BuildOutput'
if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
}

$coverageXmlPath = Join-Path $outputDirectory 'coverage.xml'

$config = New-PesterConfiguration
$config.Run.Path = @('./tests')
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = $coveragePaths
$config.CodeCoverage.OutputPath = $coverageXmlPath
$config.CodeCoverage.OutputFormat = 'JaCoCo'

$result = Invoke-Pester -Configuration $config

if ($result.FailedCount -gt 0) {
    throw "Coverage run completed with failing tests: $($result.FailedCount)"
}

$coveragePercent = $null
if ($null -ne $result.CodeCoverage -and $null -ne $result.CodeCoverage.CoveragePercent) {
    $coveragePercent = [double]$result.CodeCoverage.CoveragePercent
}
elseif ($null -ne $result.CodeCoverage -and $result.CodeCoverage.NumberOfCommandsAnalyzed -gt 0) {
    $coveragePercent = ($result.CodeCoverage.NumberOfCommandsExecuted / $result.CodeCoverage.NumberOfCommandsAnalyzed) * 100
}

if ($null -eq $coveragePercent) {
    throw 'Coverage percentage could not be determined from Pester result output.'
}

$formattedCoverage = ('{0:N2}' -f $coveragePercent)
$summaryPath = Join-Path $outputDirectory 'coverage-summary.txt'
$summaryLines = @(
    "Total coverage: $formattedCoverage%"
    "Analyzed commands: $($result.CodeCoverage.NumberOfCommandsAnalyzed)"
    "Executed commands: $($result.CodeCoverage.NumberOfCommandsExecuted)"
    "Coverage report: $coverageXmlPath"
)
$summaryLines | Set-Content -Path $summaryPath -Encoding utf8

Write-Output "[coverage] Total coverage: $formattedCoverage%"
Write-Output "[coverage] Summary written to $summaryPath"
