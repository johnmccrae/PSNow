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
    Describe 'Find-PSNowModule -Validate and empty-line filtering' {
        BeforeEach {
            Mock Write-Output {}
        }

        Context '-Validate: path exists' {
            It 'outputs the path without [STALE] when the directory is present' {
                Mock Test-Path { $true }
                Mock Get-Content { @('C:\modules\ModuleA') }

                Find-PSNowModule -Validate

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'C:\modules\ModuleA'
                } -Exactly 1 -Scope It
            }

            It 'does not append [STALE] when the directory exists' {
                Mock Test-Path { $true }
                Mock Get-Content { @('C:\modules\ModuleA') }

                Find-PSNowModule -Validate

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -match '\[STALE\]'
                } -Exactly 0 -Scope It
            }
        }

        Context '-Validate: path does not exist' {
            It 'appends [STALE] to a path that no longer exists on disk' {
                Mock Test-Path -ParameterFilter { $Path -eq $thefile } { $true }
                Mock Test-Path { $false }
                Mock Get-Content { @('C:\modules\GoneModule') }

                Find-PSNowModule -Validate

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'C:\modules\GoneModule [STALE]'
                } -Exactly 1 -Scope It
            }

            It 'marks only the missing paths while leaving present paths clean' {
                $script:testPathCallCount = 0
                Mock Test-Path {
                    param([string]$Path, [string]$PathType)
                    if ($PathType -eq 'Container') {
                        $Path -eq 'C:\modules\GoodModule'
                    }
                    else {
                        $true  # tracker file exists
                    }
                }
                Mock Get-Content { @('C:\modules\GoodModule', 'C:\modules\GoneModule') }

                Find-PSNowModule -Validate

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'C:\modules\GoodModule'
                } -Exactly 1 -Scope It

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'C:\modules\GoneModule [STALE]'
                } -Exactly 1 -Scope It
            }
        }

        Context 'empty-line filtering' {
            It 'does not output blank lines from the tracker file' {
                Mock Test-Path { $true }
                Mock Get-Content { @('C:\modules\ModuleA', '', '   ', 'C:\modules\ModuleB') }

                Find-PSNowModule

                Should -Invoke Write-Output -ParameterFilter {
                    [string]::IsNullOrWhiteSpace($InputObject)
                } -Exactly 2 -Scope It  # only the two intentional blank Write-Output "`n" calls
            }

            It 'outputs exactly the non-blank paths' {
                Mock Test-Path { $true }
                Mock Get-Content { @('C:\modules\ModuleA', '', 'C:\modules\ModuleB') }

                Find-PSNowModule

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'C:\modules\ModuleA' -or $InputObject -eq 'C:\modules\ModuleB'
                } -Exactly 2 -Scope It
            }
        }

        Context 'no -Validate: existing behaviour unchanged' {
            It 'outputs all paths as-is when -Validate is not used' {
                Mock Test-Path { $true }
                Mock Get-Content { @('C:\modules\ModuleA') }

                Find-PSNowModule  # no -Validate

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -eq 'C:\modules\ModuleA'
                } -Exactly 1 -Scope It

                Should -Invoke Write-Output -ParameterFilter {
                    $InputObject -match '\[STALE\]'
                } -Exactly 0 -Scope It
            }
        }
    }
}
