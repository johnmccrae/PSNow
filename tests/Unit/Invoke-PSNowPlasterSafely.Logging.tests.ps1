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
    Describe 'Invoke-PSNowPlasterSafely structured logging' {
        BeforeEach {
            Mock Write-Verbose {}
        }

        It 'emits a completed log with attempts=1 when Plaster succeeds on the first call' {
            Mock Invoke-Plaster {}

            # Use only static Invoke-Plaster params to avoid unintended param-stripping retries.
            Invoke-PSNowPlasterSafely -PlasterParams @{ TemplatePath = 'C:\t'; Destination = 'C:\d' }

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match '^\[op=invoke-plaster-safely, status=completed, attempts=1\]$'
            } -Exactly 1 -Scope It
        }

        It 'emits a retry log with the removed param name when an unknown parameter is stripped' {
            Mock Invoke-Plaster {}

            # GitHubUserName is a Plaster template dynamic param — the Pester mock proxy
            # does not expose it, so PowerShell raises ParameterBindingException on attempt 1.
            # Invoke-PSNowPlasterSafely strips it and retries; both a retry and completed log appear.
            Invoke-PSNowPlasterSafely -PlasterParams @{ TemplatePath = 'C:\t'; Destination = 'C:\d'; GitHubUserName = 'u' }

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=invoke-plaster-safely, status=retry' -and $Message -match 'removed_param=GitHubUserName'
            } -Exactly 1 -Scope It
        }

        It 'emits a completed log with attempts=2 after one retry' {
            Mock Invoke-Plaster {}

            Invoke-PSNowPlasterSafely -PlasterParams @{ TemplatePath = 'C:\t'; Destination = 'C:\d'; GitHubUserName = 'u' }

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=invoke-plaster-safely, status=completed, attempts=2'
            } -Exactly 1 -Scope It
        }

        It 'emits a failed log when Plaster throws an unrecoverable error' {
            Mock Invoke-Plaster { throw 'fatal error' }

            { Invoke-PSNowPlasterSafely -PlasterParams @{ TemplatePath = 'C:\t'; Destination = 'C:\d' } } | Should -Throw 'fatal error'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match 'op=invoke-plaster-safely, status=failed' -and $Message -match 'error=fatal error'
            } -Exactly 1 -Scope It
        }
    }
}
