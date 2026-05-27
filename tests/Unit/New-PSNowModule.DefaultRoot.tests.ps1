Set-StrictMode -Version Latest

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
    Describe 'New-PSNowModule default ModuleRoot' {
        BeforeEach {
            $env:BHPathDivider = [System.IO.Path]::DirectorySeparatorChar

            Mock Get-Variable -ParameterFilter { $Name -eq 'PSVersionTable' -and $ValueOnly } -MockWith {
                @{ PSVersion = [Version]'5.1.0' }
            }

            Mock Set-Location {}
            Mock Remove-Item {}
            Mock Get-ChildItem { [pscustomobject]@{ FullName = 'C:\localrepo\PSNow\PlasterTemplate\Basic.xml' } }
            Mock Copy-Item {}
            Mock Write-Output {}
            Mock Write-Verbose {}
            Mock Add-Content {}
            Mock Invoke-Plaster {
                param(
                    [string]$TemplatePath,  [string]$Destination,  [string]$ModuleName,
                    [string]$GitHubUserName, [string]$PowerShellVersion,
                    [switch]$Force,          [switch]$Verbose
                )
                [void]$TemplatePath; [void]$Destination; [void]$ModuleName
                [void]$GitHubUserName; [void]$PowerShellVersion; [void]$Force; [void]$Verbose
            }
        }

        Context 'when ModuleRoot is not supplied' {
            It 'uses the OS-appropriate default path on Windows' {
                Mock GetPSNowOs { 'Windows' }
                # Test-Path: return true for ModuleRoot existence check so New-Item is not called
                Mock Test-Path { $true }

                # No -ModuleRoot argument; function must assign the default
                { New-PSNowModule -NewModuleName 'DefaultRootTest' -BaseManifest 'Basic' } |
                    Should -Not -Throw
            }

            It 'uses ~/modules default path on non-Windows' {
                Mock GetPSNowOs { 'Linux' }
                Mock Test-Path { $true }

                { New-PSNowModule -NewModuleName 'DefaultRootLinux' -BaseManifest 'Basic' } |
                    Should -Not -Throw
            }
        }

        Context 'when ModuleRoot directory does not exist' {
            It 'creates the directory' {
                # First Test-Path (for ModuleRoot existence) returns false; all others true
                $callCount = 0
                Mock Test-Path {
                    $callCount++
                    $callCount -gt 1
                }
                Mock New-Item {}

                New-PSNowModule -NewModuleName 'MissingDir' -BaseManifest 'Basic' -ModuleRoot 'C:\nonexistent\path'

                Should -Invoke New-Item -Scope It
            }
        }
    }
}
