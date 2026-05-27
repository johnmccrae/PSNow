Set-StrictMode -Version Latest

# CONTRACT TESTS — New-PSNowModule parameter validation
#
# These tests document and enforce the observable interface contract of
# New-PSNowModule. They are intentionally narrow: each test asserts one
# specific promise the function makes to its callers.
#
# Why contract tests?
#   Unit tests verify behaviour given valid inputs. Contract tests verify the
#   *boundary* — what happens at the edges of the parameter space. If a
#   contract test starts failing, it means the public API surface changed and
#   callers may be broken.
#
# Update guidance (for future boundary changes):
#   1. Add a ValidateSet value → add an "accepts '<NewValue>'" It block.
#   2. Remove a ValidateSet value → remove its acceptance test, add a rejection test.
#   3. Change ValidateNotNullOrWhiteSpace to ValidateNotNullOrEmpty → remove the
#      whitespace test and document that whitespace is now a legal name.
#   4. After any change, run: pwsh -NoProfile -NonInteractive -File ./Build/build.ps1 -TaskList test

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$moduleManifestCandidates = @(
    (Join-Path $repoRoot 'Staging\PSNow\PSNow.psd1')
    (Join-Path $repoRoot 'PSNow.psd1')
)
$moduleManifestPath = $moduleManifestCandidates | Where-Object { Test-Path -Path $_ } | Select-Object -First 1

Remove-Module -Name PSNow -Force -ErrorAction SilentlyContinue
if (-not [string]::IsNullOrWhiteSpace($moduleManifestPath)) {
    Import-Module -Name $moduleManifestPath -Force -ErrorAction Stop
}

InModuleScope -ModuleName PSNow {

    # Shared mock setup for tests that need the function body to execute
    # (i.e. tests that pass parameter validation but need side-effects suppressed).

    # -----------------------------------------------------------------------
    # Contract: -NewModuleName
    # Promise: [ValidateNotNullOrWhiteSpace()] — null, empty, and whitespace
    # are all rejected before the function body runs.
    # -----------------------------------------------------------------------
    Describe 'New-PSNowModule contract: -NewModuleName' {

        It 'rejects an empty string — rationale: empty name produces an unusable module directory' {
            # Rationale: an empty name would create a module at "$ModuleRoot\" with
            # no subdirectory, silently overwriting the root. ValidateNotNullOrWhiteSpace
            # must catch this before any file I/O occurs.
            { New-PSNowModule -NewModuleName '' -BaseManifest 'Basic' -ModuleRoot 'c:\modules' } |
                Should -Throw
        }

        It 'rejects a whitespace-only string — rationale: whitespace names are indistinguishable from empty at the filesystem level' {
            { New-PSNowModule -NewModuleName '   ' -BaseManifest 'Basic' -ModuleRoot 'c:\modules' } |
                Should -Throw
        }
    }

    # -----------------------------------------------------------------------
    # Contract: -BaseManifest
    # Promise: [ValidateSet("Basic","Extended","Advanced")] — only these three
    # values are accepted; the match is case-insensitive (PowerShell default).
    # -----------------------------------------------------------------------
    Describe 'New-PSNowModule contract: -BaseManifest rejection' {

        It 'rejects an unrecognised manifest value — rationale: prevents silent fallback to a non-existent template' {
            # Rationale: if an unknown manifest name were silently ignored or
            # defaulted, the caller would get an unexpected scaffold layout with
            # no error. The ValidateSet must surface this as a hard error.
            { New-PSNowModule -NewModuleName 'Test' -BaseManifest 'Premium' -ModuleRoot 'c:\modules' } |
                Should -Throw
        }
    }

    Describe 'New-PSNowModule contract: -BaseManifest case-insensitivity' {
        # Rationale: ValidateSet is case-insensitive by default in PowerShell.
        # Callers must not be forced to remember exact casing of manifest names.
        BeforeEach {
            $env:BHPathDivider = [System.IO.Path]::DirectorySeparatorChar
            Mock Get-Variable -ParameterFilter { $Name -eq 'PSVersionTable' -and $ValueOnly } -MockWith {
                @{ PSVersion = [Version]'5.1.0' }
            }
            Mock GetPSNowOs { 'Windows' }
            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-Item {}
            Mock Get-ChildItem { [pscustomobject]@{ FullName = 'C:\localrepo\PSNow\PlasterTemplate\Basic.xml' } }
            Mock New-Item {}
            Mock Copy-Item {}
            Mock Write-Output {}
            Mock Write-Verbose {}
            Mock Add-Content {}
            Mock Invoke-Plaster {
                param(
                    [string]$TemplatePath, [string]$Destination, [string]$ModuleName,
                    [string]$GitHubUserName, [string]$PowerShellVersion,
                    [switch]$Force, [switch]$Verbose
                )
                [void]$TemplatePath; [void]$Destination; [void]$ModuleName
                [void]$GitHubUserName; [void]$PowerShellVersion; [void]$Force; [void]$Verbose
            }
        }

        It 'accepts "basic" (lowercase)' {
            { New-PSNowModule -NewModuleName 'LcBasic' -BaseManifest 'basic' -ModuleRoot 'c:\modules' } |
                Should -Not -Throw
        }

        It 'accepts "extended" (lowercase)' {
            { New-PSNowModule -NewModuleName 'LcExtended' -BaseManifest 'extended' -ModuleRoot 'c:\modules' } |
                Should -Not -Throw
        }

        It 'accepts "advanced" (lowercase)' {
            { New-PSNowModule -NewModuleName 'LcAdvanced' -BaseManifest 'advanced' -ModuleRoot 'c:\modules' } |
                Should -Not -Throw
        }
    }

    # -----------------------------------------------------------------------
    # Contract: -ModuleRoot (optional)
    # Promise: an empty string is treated identically to an omitted parameter —
    # the function silently assigns the OS-appropriate default path.
    # -----------------------------------------------------------------------
    Describe 'New-PSNowModule contract: -ModuleRoot empty string' {
        BeforeEach {
            $env:BHPathDivider = [System.IO.Path]::DirectorySeparatorChar
            Mock Get-Variable -ParameterFilter { $Name -eq 'PSVersionTable' -and $ValueOnly } -MockWith {
                @{ PSVersion = [Version]'5.1.0' }
            }
            Mock GetPSNowOs { 'Windows' }
            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-Item {}
            Mock Get-ChildItem { [pscustomobject]@{ FullName = 'C:\localrepo\PSNow\PlasterTemplate\Basic.xml' } }
            Mock New-Item {}
            Mock Copy-Item {}
            Mock Write-Output {}
            Mock Write-Verbose {}
            Mock Add-Content {}
            Mock Invoke-Plaster {
                param(
                    [string]$TemplatePath, [string]$Destination, [string]$ModuleName,
                    [string]$GitHubUserName, [string]$PowerShellVersion,
                    [switch]$Force, [switch]$Verbose
                )
                [void]$TemplatePath; [void]$Destination; [void]$ModuleName
                [void]$GitHubUserName; [void]$PowerShellVersion; [void]$Force; [void]$Verbose
            }
        }

        It 'treats empty string as omitted — rationale: callers that pass $ModuleRoot="" must not get a broken path' {
            # Rationale: scripts that conditionally set $ModuleRoot and pass it
            # through unset (empty) must get the same OS default as omitting it.
            # The guard `if (!$ModuleRoot)` treats "" as falsy, which is the
            # documented contract.
            { New-PSNowModule -NewModuleName 'EmptyRoot' -BaseManifest 'Basic' -ModuleRoot '' } |
                Should -Not -Throw
        }
    }
}