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
    Describe 'Invoke-PSNowPlasterSafely' {

        Context 'when Invoke-Plaster succeeds on the first call' {
            It 'calls Invoke-Plaster exactly once' {
                Mock Invoke-Plaster {}

                Invoke-PSNowPlasterSafely -PlasterParams @{ TemplatePath = 'C:\t'; Destination = 'C:\d' }

                Should -Invoke Invoke-Plaster -Exactly 1 -Scope It
            }

            It 'does not throw' {
                Mock Invoke-Plaster {}

                {
                    Invoke-PSNowPlasterSafely -PlasterParams @{ TemplatePath = 'C:\t'; Destination = 'C:\d' }
                } | Should -Not -Throw
            }
        }

        Context 'when Invoke-Plaster raises ParameterBindingException for a known param' {
            # GitHubUserName is not a static Invoke-Plaster parameter; it is a dynamic parameter
            # that Plaster injects from the template manifest at runtime. The Pester mock proxy
            # does not expose it, so the PowerShell param-binder raises ParameterBindingException
            # on the first call. Invoke-PSNowPlasterSafely must strip the param and retry.
            It 'does not throw after stripping the unrecognised param and retrying' {
                Mock Invoke-Plaster {}

                {
                    Invoke-PSNowPlasterSafely -PlasterParams @{
                        TemplatePath   = 'C:\t'
                        Destination    = 'C:\d'
                        GitHubUserName = 'testuser'
                    }
                } | Should -Not -Throw
            }

            It 'calls Invoke-Plaster at least once after the retry' {
                Mock Invoke-Plaster {}

                Invoke-PSNowPlasterSafely -PlasterParams @{
                    TemplatePath   = 'C:\t'
                    Destination    = 'C:\d'
                    GitHubUserName = 'testuser'
                }

                Should -Invoke Invoke-Plaster -Scope It
            }
        }

        Context 'when ParameterBindingException names a param not in the splat' {
            It 'rethrows rather than looping forever' {
                Mock Invoke-Plaster {
                    throw [System.Management.Automation.ParameterBindingException]::new(
                        "A parameter cannot be found that matches parameter name 'UnknownParam'."
                    )
                }

                {
                    Invoke-PSNowPlasterSafely -PlasterParams @{ TemplatePath = 'C:\t'; Destination = 'C:\d' }
                } | Should -Throw
            }
        }

        Context 'when Invoke-Plaster throws a non-binding exception' {
            It 'rethrows the original error unchanged' {
                Mock Invoke-Plaster { throw [System.IO.IOException]::new('disk full') }

                {
                    Invoke-PSNowPlasterSafely -PlasterParams @{ TemplatePath = 'C:\t'; Destination = 'C:\d' }
                } | Should -Throw 'disk full'
            }
        }
    }
}
