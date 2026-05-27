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
    Describe 'Write-PSNowScriptNoWhitespace' {
        BeforeEach {
            Mock Resolve-Path { 'C:\fake\module' }
            Mock Split-Path { 'C:\fake\module' }
            Mock Set-Location {}
            Mock Get-ChildItem { @() }
            Mock Get-Content { @() }
            Mock Set-Content {}
        }

        It 'sets the working location to the project root' {
            Write-PSNowScriptNoWhitespace

            Should -Invoke Set-Location -Exactly 1 -Scope It
        }

        It 'enumerates scripts under the module root' {
            Write-PSNowScriptNoWhitespace

            Should -Invoke Get-ChildItem -Exactly 1 -Scope It
        }

        Context 'when script files are found' {
            BeforeEach {
                $fakeFile = [pscustomobject]@{ FullName = 'C:\fake\module\Public\Test.ps1' }
                Mock Get-ChildItem { $fakeFile }
                Mock Get-Content { @('line one   ', 'line two  ') }
            }

            It 'reads each script file' {
                Write-PSNowScriptNoWhitespace

                Should -Invoke Get-Content -Exactly 1 -Scope It
            }

            It 'writes trimmed content back to each script file' {
                Write-PSNowScriptNoWhitespace

                Should -Invoke Set-Content -Scope It
            }
        }
    }
}
