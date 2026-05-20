Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$moduleManifestCandidates = @(
    (Join-Path $repoRoot 'Staging' 'PSNow' 'PSNow.psd1')
    (Join-Path $repoRoot 'PSNow.psd1')
)
$moduleManifestPath = $moduleManifestCandidates | Where-Object { Test-Path -Path $_ } | Select-Object -First 1

Remove-Module -Name PSNow -Force -ErrorAction SilentlyContinue
if (-not [string]::IsNullOrWhiteSpace($moduleManifestPath)) {
    Import-Module -Name $moduleManifestPath -Force -ErrorAction Stop
}

InModuleScope -ModuleName PSNow {
    Describe 'New-PSNowModule structured logging' {
        BeforeEach {
            $env:BHPathDivider = [System.IO.Path]::DirectorySeparatorChar

            Mock Get-Variable -ParameterFilter { $Name -eq 'PSVersionTable' -and $ValueOnly } -MockWith {
                @{ PSVersion = [Version]'5.1.0' }
            }

            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-Item {}
            Mock Get-ChildItem { [pscustomobject]@{ FullName = 'C:\localrepo\PSNow\PlasterTemplate\Basic.xml' } }
            Mock New-Item {}
            Mock Write-Output {}
            Mock Add-Content {}
            Mock Copy-Item {}
            Mock Write-Verbose {}
            Mock Invoke-Plaster {
                param(
                    [string]$TemplatePath,
                    [string]$Destination,
                    [string]$ModuleName,
                    [string]$GitHubUserName,
                    [string]$PowerShellVersion,
                    [switch]$Force,
                    [switch]$Verbose
                )

                # Keep parameters intentionally referenced to satisfy analyzer in test-only mocks.
                [void]$TemplatePath
                [void]$Destination
                [void]$ModuleName
                [void]$GitHubUserName
                [void]$PowerShellVersion
                [void]$Force
                [void]$Verbose
            }
        }

        It 'emits started and completed verbose logs with consistent core fields' {
            $null = New-PSNowModule -NewModuleName 'LoggingDemo' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match '^\[op=invoke-plaster, status=started, elapsed_ms=0, module_name=LoggingDemo, manifest=Basic, destination=c:\\modules\]$'
            } -Exactly 1 -Scope It

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match '^\[op=invoke-plaster, status=completed, elapsed_ms=\d+, module_name=LoggingDemo, manifest=Basic, destination=c:\\modules\]$'
            } -Exactly 1 -Scope It
        }

        It 'emits a failed verbose log when Invoke-Plaster throws' {
            Mock Invoke-Plaster {
                param(
                    [string]$TemplatePath,
                    [string]$Destination,
                    [string]$ModuleName,
                    [string]$GitHubUserName,
                    [string]$PowerShellVersion,
                    [switch]$Force,
                    [switch]$Verbose
                )

                # Keep parameters intentionally referenced to satisfy analyzer in test-only mocks.
                [void]$TemplatePath
                [void]$Destination
                [void]$ModuleName
                [void]$GitHubUserName
                [void]$PowerShellVersion
                [void]$Force
                [void]$Verbose

                throw 'plaster failed'
            }

            {
                New-PSNowModule -NewModuleName 'LoggingDemo' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'
            } | Should -Throw 'plaster failed'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match '^\[op=invoke-plaster, status=failed, elapsed_ms=\d+, module_name=LoggingDemo, manifest=Basic, destination=c:\\modules, error=plaster failed\]$'
            } -Exactly 1 -Scope It
        }
    }
}