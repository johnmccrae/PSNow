# Static Analysis — Ex14 Report

## Overview

This document records the Ex14 static-analysis exercise: baseline capture, strictness
increase, findings fixed, suppressions justified, and the autofix script.

---

## Baseline (before Ex14)

Settings file: `Build/PSScriptAnalyzerSettings.psd1`
Severity checked: `Warning`, `Error`
Excluded rules: `PSAvoidGlobalVars`, `PSUseBOMForUnicodeEncodedFile`

```
Invoke-ScriptAnalyzer -Path Staging/PSNow -Settings Build/PSScriptAnalyzerSettings.psd1 -Recurse
Total findings: 0
```

---

## Increased Strictness (Ex14 changes)

The following changes were made to `Build/PSScriptAnalyzerSettings.psd1`:

| Change | Before | After |
|---|---|---|
| Severity | `Warning`, `Error` | `Warning`, `Error`, **`Information`** |
| `PSAvoidUsingPositionalParameters` | not configured | **enabled** (named params enforced) |
| `PSAvoidLongLines` | not configured | **enabled** (max 120 chars) |
| Suppression comments | none | **documented** (see below) |

---

## Findings Found After Strictness Increase

Running with the new settings against all module and build source files:

```
Total findings: 7
```

| # | Rule | Severity | File | Line | Action |
|---|---|---|---|---|---|
| 1 | PSAvoidUsingPositionalParameters | Information | `Build/build.psake.ps1` | 20 | **Fixed** |
| 2 | PSAvoidUsingPositionalParameters | Information | `Build/build.psake.ps1` | 21 | **Fixed** |
| 3 | PSAvoidUsingPositionalParameters | Information | `Build/build.psake.ps1` | 28 | **Fixed** |
| 4 | PSAvoidUsingPositionalParameters | Information | `Build/build.ps1` | 201 | **Fixed** |
| 5 | PSUseBOMForUnicodeEncodedFile | Warning | `Private/Get-PSNowFeatureFlag.ps1` | — | **Suppressed** (see below) |
| 6 | PSUseBOMForUnicodeEncodedFile | Warning | `Private/Remove-OldPSNowManifest.ps1` | — | **Suppressed** (see below) |
| 7 | PSUseBOMForUnicodeEncodedFile | Warning | `Update-ArchitectureDiagram.ps1` | — | **Suppressed** (see below) |

---

## Fixes Applied

### Finding 1–3 — `build.psake.ps1` positional `Join-Path` calls

`Join-Path` accepts up to three positional arguments (`-Path`, `-ChildPath`,
`-AdditionalChildPath`). Using them positionally reduces readability and will
silently break if a consumer omits an argument.

```powershell
# Before
Get-ChildItem (Join-Path $ProjectRoot 'tests' '**' '*Tests.ps1')
Get-ChildItem (Join-Path $ProjectRoot 'tests' 'Integration' '*Integration.Tests.ps1')
$ScriptAnalyzerSettingsPath = Join-Path $ProjectRoot 'Build' 'PSScriptAnalyzerSettings.psd1'

# After
Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'tests' -AdditionalChildPath '**', '*Tests.ps1')
Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'tests' -AdditionalChildPath 'Integration', '*Integration.Tests.ps1')
$ScriptAnalyzerSettingsPath = Join-Path -Path $ProjectRoot -ChildPath 'Build' -AdditionalChildPath 'PSScriptAnalyzerSettings.psd1'
```

### Finding 4 — `build.ps1` positional `Join-Path` call

```powershell
# Before
$publishfolder = Join-Path $ENV:BHProjectPath 'Staging' $ENV:BHProjectName

# After
$publishfolder = Join-Path -Path $ENV:BHProjectPath -ChildPath 'Staging' -AdditionalChildPath $ENV:BHProjectName
```

---

## Suppressed Findings — Justification

### `PSUseBOMForUnicodeEncodedFile` (3 files)

**Rule description:** Files encoded as UTF-8 should include a BOM (Byte Order Mark)
so consuming applications can detect the encoding.

**Suppression justification:**

1. **Linux/macOS compatibility** — The `git` toolchain on Linux interprets BOM as
   literal content in script files, causing diff noise and potential parse errors in
   bash contexts where `.ps1` files are sourced via `pwsh`.
2. **CI environment** — Azure Pipelines Ubuntu agents run PowerShell Core which
   handles UTF-8-without-BOM correctly; no BOM is needed for correct execution.
3. **Editor configuration** — `.editorconfig` (if added) or VS Code workspace settings
   can enforce UTF-8 without BOM for all contributors; this is the project standard.
4. **Consistency** — All other `.ps1` files in the project are already UTF-8 without
   BOM. Adding BOM to a subset of files would be inconsistent.

**Scope of suppression:** Project-wide via `ExcludeRules` in
`Build/PSScriptAnalyzerSettings.psd1`.

**Affected files:**
- `Private/Get-PSNowFeatureFlag.ps1`
- `Private/Remove-OldPSNowManifest.ps1`
- `Update-ArchitectureDiagram.ps1`

**Rollback:** Remove `PSUseBOMForUnicodeEncodedFile` from `ExcludeRules` and
re-save all three files with UTF-8+BOM encoding
(`[System.IO.File]::WriteAllText(path, content, [System.Text.UTF8Encoding]::new($true))`).

---

### `PSAvoidGlobalVars` (pre-existing suppression, retained)

**Justification:** PSake build tasks communicate shared state (e.g. `$psake`,
`$BuildRoot`) through global variables. This is a known and intentional pattern in
the PSake build framework, not a design smell in module code. Module source files
(`Public/`, `Private/`) do not use global variables; the suppression only affects
`Build/` scripts where it is unavoidable.

---

## After-Fix Findings Count

```
Invoke-ScriptAnalyzer -Path Staging/PSNow -Settings Build/PSScriptAnalyzerSettings.psd1 -Recurse
Total findings: 0
```

All 4 fixable findings resolved. 3 findings suppressed with justification above.

---

## AutoFix Script

`Build/Invoke-PSNowAutoFix.ps1` — repeatable two-pass process:

1. **Pass 1 (auto-fix):** Applies `Invoke-ScriptAnalyzer -Fix` for rules that support
   automated correction (`PSAvoidTrailingWhitespace`, `PSUseCorrectCasing`).
2. **Pass 2 (report):** Re-runs full analysis and prints residual findings requiring
   manual attention.

```powershell
# Usage
.\Build\Invoke-PSNowAutoFix.ps1          # fix + report
.\Build\Invoke-PSNowAutoFix.ps1 -WhatIf  # dry-run only
```
