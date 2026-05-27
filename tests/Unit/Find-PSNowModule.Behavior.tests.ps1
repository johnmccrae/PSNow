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
    Describe 'Find-PSNowModule behavior' {
        BeforeEach {
            Mock Write-Output {}
            Mock Test-Path { $false }
            Mock Get-Content { @() }
        }

        Context 'when currentmodules.txt does not exist' {
            It 'outputs a friendly no-modules message' {
                Mock Test-Path { $false }

                Find-PSNowModule

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'No modules have been created with PSNow yet.'
                } -Exactly 1 -Scope It
            }

            It 'does not read the tracker file when it is missing' {
                Mock Test-Path { $false }

                Find-PSNowModule

                Should -Invoke Get-Content -Exactly 0 -Scope It
            }
        }

        Context 'when currentmodules.txt exists with entries' {
            BeforeEach {
                Mock Test-Path { $true }
                Mock Get-Content { @('C:\modules\ModuleA', 'C:\modules\ModuleB') }
            }

            It 'reads the tracker file' {
                Find-PSNowModule

                Should -Invoke Get-Content -Exactly 1 -Scope It
            }

            It 'outputs the section header' {
                Find-PSNowModule

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq "Here's your list of PSNow Modules"
                } -Exactly 1 -Scope It
            }

            It 'outputs the separator line' {
                Find-PSNowModule

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq '---------------------------------'
                } -Exactly 1 -Scope It
            }

            It 'outputs each module path' {
                Find-PSNowModule

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'C:\modules\ModuleA'
                } -Exactly 1 -Scope It

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'C:\modules\ModuleB'
                } -Exactly 1 -Scope It
            }
        }

        Context 'when currentmodules.txt exists but is empty' {
            BeforeEach {
                Mock Test-Path { $true }
                Mock Get-Content { @() }
            }

            It 'outputs the header without any module paths' {
                Find-PSNowModule

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq "Here's your list of PSNow Modules"
                } -Exactly 1 -Scope It

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -match '^C:\\'
                } -Exactly 0 -Scope It
            }
        }
    }
}
