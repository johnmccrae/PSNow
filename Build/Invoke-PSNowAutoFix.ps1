<#
.SYNOPSIS
    Runs PSScriptAnalyzer with the project's strict settings and auto-corrects
    findings that PSSA can fix automatically.

.DESCRIPTION
    This script is the repeatable auto-fix entry point for PSNow static analysis.
    It performs two passes:
      1. Auto-fix pass  — uses Invoke-ScriptAnalyzer -Fix for rules that support
         automated correction (e.g. PSUseCorrectCasing, PSAvoidTrailingWhitespace).
      2. Report pass    — re-runs the full analysis and prints any remaining findings
         that require manual attention.

    Scope is limited to the module source folders (Public/ and Private/) plus the
    Build/ scripts. Test files are excluded because test helpers intentionally
    use patterns (e.g. positional params in mocks) that would otherwise trigger
    Information-level findings.

.PARAMETER TargetPath
    Root path to analyse. Defaults to the repository root derived from this
    script's location.

.PARAMETER WhatIf
    Report findings without applying any fixes.

.EXAMPLE
    # Run from repo root — auto-fixes and then reports residuals
    .\Build\Invoke-PSNowAutoFix.ps1

.EXAMPLE
    # Dry-run: show what would be fixed without changing files
    .\Build\Invoke-PSNowAutoFix.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TargetPath = (Split-Path -Path $PSScriptRoot -Parent)
)

Set-StrictMode -Version Latest

$settingsPath = Join-Path -Path $PSScriptRoot -ChildPath 'PSScriptAnalyzerSettings.Strict.psd1'
$scanFolders  = @(
    (Join-Path -Path $TargetPath -ChildPath 'Public'),
    (Join-Path -Path $TargetPath -ChildPath 'Private'),
    (Join-Path -Path $TargetPath -ChildPath 'Build')
)

# Rules that support -Fix in PSScriptAnalyzer 1.x
$autoFixableRules = @(
    'PSAvoidTrailingWhitespace',
    'PSUseCorrectCasing'
)

Write-Information -MessageData "`n=== PSNow AutoFix: Pass 1 — applying automatic corrections ===" -InformationAction Continue

foreach ($folder in $scanFolders) {
    if (-not (Test-Path -Path $folder)) { continue }

    $files = Get-ChildItem -Path $folder -Include '*.ps1', '*.psm1' -Recurse
    foreach ($file in $files) {
        $fixResults = Invoke-ScriptAnalyzer -Path $file.FullName `
            -Settings $settingsPath `
            -IncludeRule $autoFixableRules `
            -Fix:(-not $WhatIfPreference)

        if ($fixResults) {
            foreach ($r in $fixResults) {
                Write-Information -MessageData "  [FIXED] $($file.Name):$($r.Line) — $($r.RuleName)" -InformationAction Continue
            }
        }
    }
}

Write-Information -MessageData "`n=== PSNow AutoFix: Pass 2 — reporting residual findings ===" -InformationAction Continue

$residual = @()
foreach ($folder in $scanFolders) {
    if (-not (Test-Path -Path $folder)) { continue }
    $residual += Invoke-ScriptAnalyzer -Path $folder -Recurse -Settings $settingsPath
}

if ($residual.Count -eq 0) {
    Write-Information -MessageData "`n  [CLEAN] No findings — all checks pass." -InformationAction Continue
}
else {
    Write-Information -MessageData "`n  $($residual.Count) finding(s) require manual attention:" -InformationAction Continue
    $residual | Format-Table -Property Severity, RuleName, ScriptName, Line, Message -AutoSize -Wrap
}

return $residual.Count
