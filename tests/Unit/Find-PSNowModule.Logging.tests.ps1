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
    Describe 'Find-PSNowModule structured logging' {
        BeforeEach {
            Mock Write-Verbose {}
            Mock Write-Output {}
        }

        It 'emits a started log before checking the module list file' {
            Mock Test-Path { $false }

            Find-PSNowModule

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=find-modules, status=started'
            } -Exactly 1 -Scope It
        }

        It 'emits a not-found log when currentmodules.txt does not exist' {
            Mock Test-Path { $false }

            Find-PSNowModule

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=find-modules, status=not-found'
            } -Exactly 1 -Scope It
        }

        It 'does not emit a completed log when the file does not exist' {
            Mock Test-Path { $false }

            Find-PSNowModule

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'status=completed'
            } -Exactly 0 -Scope It
        }

        It 'emits a completed log with the module count when the file exists' {
            Mock Test-Path { $true }
            Mock Get-Content { @('C:\modules\ModA', 'C:\modules\ModB') }

            Find-PSNowModule

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=find-modules, status=completed' -and $Message -match 'count=2'
            } -Exactly 1 -Scope It
        }

        It 'emits started then completed (never not-found) when the file exists' {
            Mock Test-Path { $true }
            Mock Get-Content { @('C:\modules\ModA') }

            Find-PSNowModule

            Should -Invoke Write-Verbose -ParameterFilter { $Message -match 'status=started' } -Exactly 1 -Scope It
            Should -Invoke Write-Verbose -ParameterFilter { $Message -match 'status=completed' } -Exactly 1 -Scope It
            Should -Invoke Write-Verbose -ParameterFilter { $Message -match 'status=not-found' } -Exactly 0 -Scope It
        }
    }
}
