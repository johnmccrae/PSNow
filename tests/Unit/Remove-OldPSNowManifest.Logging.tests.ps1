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
    Describe 'Remove-OldPSNowManifest structured logging' {
        BeforeEach {
            Mock Remove-Item {}
            Mock Copy-Item {}
            Mock Write-Verbose {}
        }

        It 'emits a started log at the beginning of manifest setup' {
            Mock Test-Path { $false }

            Remove-OldPSNowManifest -TemplateRoot 'C:\repo' -BaseManifest 'Basic'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match '^\[op=manifest-setup, status=started, manifest=Basic\]$'
            } -Exactly 1 -Scope It
        }

        It 'emits a completed log after copying the manifest' {
            Mock Test-Path { $false }

            Remove-OldPSNowManifest -TemplateRoot 'C:\repo' -BaseManifest 'Extended'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=manifest-setup, status=completed, manifest=Extended'
            } -Exactly 1 -Scope It
        }

        It 'emits a removed log when an existing upper-case manifest is found and deleted' {
            Mock Test-Path {
                param([string]$Path)
                # Case-sensitive match so only PlasterManifest.xml (capital P) returns true.
                $Path -clike '*PlasterManifest.xml'
            }

            Remove-OldPSNowManifest -TemplateRoot 'C:\repo' -BaseManifest 'Basic'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=manifest-setup, status=removed' -and $Message -match 'PlasterManifest\.xml'
            } -Exactly 1 -Scope It
        }

        It 'emits a removed log when an existing lower-case manifest is found and deleted' {
            Mock Test-Path {
                param([string]$Path)
                # Case-sensitive match so only plasterManifest.xml (lowercase p) returns true.
                $Path -clike '*plasterManifest.xml'
            }

            Remove-OldPSNowManifest -TemplateRoot 'C:\repo' -BaseManifest 'Basic'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=manifest-setup, status=removed' -and $Message -match 'plasterManifest\.xml'
            } -Exactly 1 -Scope It
        }
    }
}
