<#
.SYNOPSIS
Runs Pester with code coverage and writes an advisory markdown summary
to the Azure Pipelines job summary (##vso[task.uploadsummary]).

.NOTES
This script is intentionally non-blocking: any failure exits with code 0
so it cannot prevent a merge.
#>
# PSUseBOMForUnicodeEncodedFile: this file contains only ASCII characters; a UTF-8 BOM
# is not required and would unnecessarily alter the byte-order mark for downstream consumers.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseBOMForUnicodeEncodedFile', '',
    Justification = 'File contains only ASCII characters; UTF-8 BOM is not required.')]
[CmdletBinding()]
param(
    [string]$ProjectRoot = $env:BHProjectPath,
    [string]$StagingPath = (Join-Path -Path $env:BHProjectPath -ChildPath 'Staging' -AdditionalChildPath $env:BHProjectName)
)

try {
    $testScripts = @(
        Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'tests' -AdditionalChildPath '**', '*Tests.ps1') -ErrorAction SilentlyContinue
    )

    $sourceFiles = @(
        Get-ChildItem (Join-Path -Path $StagingPath -ChildPath 'Public'  -AdditionalChildPath '*.ps1') -ErrorAction SilentlyContinue
        Get-ChildItem (Join-Path -Path $StagingPath -ChildPath 'Private' -AdditionalChildPath '*.ps1') -ErrorAction SilentlyContinue
    )

    if ($testScripts.Count -eq 0 -or $sourceFiles.Count -eq 0) {
        Write-Warning 'Coverage summary skipped: no test scripts or source files found.'
        exit 0
    }

    $config = New-PesterConfiguration
    $config.Run.Path             = [string[]]$testScripts.FullName
    $config.Run.PassThru         = $true
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path    = [string[]]$sourceFiles.FullName
    $config.Output.Verbosity     = 'None'

    $result = Invoke-Pester -Configuration $config

    $cov     = $result.CodeCoverage
    $pct     = if ($cov.CommandsAnalyzedCount -gt 0) {
        [math]::Round(($cov.CommandsExecutedCount / $cov.CommandsAnalyzedCount) * 100, 1)
    } else { 0 }

    $passed  = $result.PassedCount
    $failed  = $result.FailedCount
    $total   = $result.TotalCount
    $elapsed = [math]::Round($result.Duration.TotalSeconds, 1)

    # Build markdown
    $badge = if ($pct -ge 80) { '🟢' } elseif ($pct -ge 60) { '🟡' } else { '🔴' }

    $md = @"
# $badge PSNow CI Summary

| Metric | Value |
|--------|-------|
| Tests passed | $passed / $total |
| Tests failed | $failed |
| Code coverage | $pct% ($($cov.CommandsExecutedCount) / $($cov.CommandsAnalyzedCount) commands) |
| Duration | ${elapsed}s |
| Agent OS | $(if ($env:AGENT_OS) { $env:AGENT_OS } elseif ($IsWindows) { 'Windows_NT' } else { 'Linux' }) |
| Branch | $(if ($env:BUILD_SOURCEBRANCH) { $env:BUILD_SOURCEBRANCH } else { $env:BHBranchName }) |
| Build | $(if ($env:BUILD_BUILDNUMBER) { $env:BUILD_BUILDNUMBER } else { $env:BHBuildNumber }) |

> **Advisory only** — this summary does not block merges.
"@

    if ($cov.CommandsMissedCount -gt 0) {
        $missedCmds = $cov.CommandsMissed | Select-Object -First 10
        $md += "`n`n## Missed Commands (top 10)`n`n| File | Line | Command |`n|------|------|---------|`n"
        foreach ($cmd in $missedCmds) {
            $file = Split-Path $cmd.File -Leaf
            $md  += "| $file | $($cmd.Line) | ``$($cmd.Text -replace '\|','&#124;')`` |`n"
        }
    }

    $summaryFile = Join-Path ([System.IO.Path]::GetTempPath()) 'psnow-ci-summary.md'
    $md | Out-File -FilePath $summaryFile -Encoding utf8 -Force

    # Upload to Azure Pipelines job summary
    Write-Output "##vso[task.uploadsummary]$summaryFile"

    Write-Output "`nCoverage summary written: $pct% ($passed/$total tests passed)"
}
catch {
    Write-Warning "Coverage summary step encountered an error: $_"
}

# Always exit 0 — this step is advisory only
exit 0
