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

    Describe 'Get-PSNowTempDirectory supplemental' {

        Context 'Linux path (non-Windows, non-macOS)' {
            It 'returns GetTempPath trimmed of directory separator' {
                Mock GetPSNowOs { 'Linux' }

                $result = Get-PSNowTempDirectory

                $result | Should -Not -BeNullOrEmpty
                $result | Should -Not -Match ([regex]::Escape([System.IO.Path]::DirectorySeparatorChar) + '$')
            }
        }
    }

    Describe 'Get-PSNowTempRegistry supplemental' {

        Context 'when the registry key does not yet exist' {
            It 'creates the registry key' {
                Mock Test-Path { $false }
                Mock New-Item {}

                Get-PSNowTempRegistry | Out-Null

                Should -Invoke New-Item -Exactly 1 -Scope It
            }
        }

        Context 'when registry key creation fails' {
            It 'throws a wrapped exception with descriptive message' {
                Mock Test-Path { $false }
                Mock New-Item { throw [Exception]::new('access denied') }

                {
                    Get-PSNowTempRegistry
                } | Should -Throw 'Was not able to create a Pester Registry key for TestRegistry'
            }
        }
    }
}
