Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$moduleManifestCandidates = @(
    (Join-Path $repoRoot 'PSNow.psd1')
    (Join-Path $repoRoot 'Staging' 'PSNow' 'PSNow.psd1')
)
$moduleManifestPath = $moduleManifestCandidates | Where-Object { Test-Path -Path $_ } | Select-Object -First 1

Remove-Module -Name PSNow -Force -ErrorAction SilentlyContinue
if (-not [string]::IsNullOrWhiteSpace($moduleManifestPath)) {
    Import-Module -Name $moduleManifestPath -Force -ErrorAction Stop
}

InModuleScope -ModuleName PSNow {
    Describe 'New-PSNowModule PSNOW_DISABLE_RETRY toggle' {
        BeforeEach {
            Remove-Item Env:PSNOW_DISABLE_RETRY -ErrorAction SilentlyContinue
            $env:BHPathDivider = [System.IO.Path]::DirectorySeparatorChar

            Mock Get-Variable -ParameterFilter { $Name -eq 'PSVersionTable' -and $ValueOnly } -MockWith {
                @{ PSVersion = [Version]'7.0.0' }
            }
            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-Item {}
            Mock Get-ChildItem { [pscustomobject]@{ FullName = 'C:\localrepo\PSNow\PlasterTemplate\Basic.xml' } }
            Mock New-Item {}
            Mock Add-Content {}
            Mock Copy-Item {}
            Mock Write-Verbose {}
            Mock Write-Output {}
            Mock Write-PSNowStructuredLog {}
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
                [void]$TemplatePath; [void]$Destination; [void]$ModuleName
                [void]$GitHubUserName; [void]$PowerShellVersion; [void]$Force; [void]$Verbose
            }
        }

        AfterEach {
            Remove-Item Env:PSNOW_DISABLE_RETRY -ErrorAction SilentlyContinue
        }

        Context 'flag OFF (default) — retry loop is active' {
            It 'calls Invoke-Plaster once when no ParameterBindingException is raised' {
                $null = New-PSNowModule -NewModuleName 'RetryOff' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'

                Should -Invoke Invoke-Plaster -Exactly 1 -Scope It
            }

            It 'emits retrying log entries when Invoke-Plaster proxy throws for dynamic parameters' {
                # The Pester mock proxy for Invoke-Plaster lacks Plaster dynamic params
                # (PowerShellVersion, GitHubUserName). The retry loop catches those
                # ParameterBindingExceptions and emits a structured log for each.
                $null = New-PSNowModule -NewModuleName 'RetryOff2' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'

                Should -Invoke Write-PSNowStructuredLog -ParameterFilter { $Status -eq 'retrying' } -Scope It
            }
        }

        Context 'flag ON — retry loop is bypassed (fast-fail)' {
            It 'propagates ParameterBindingException immediately with no retrying log when PSNOW_DISABLE_RETRY=1' {
                $env:PSNOW_DISABLE_RETRY = '1'

                { New-PSNowModule -NewModuleName 'RetryOn' -BaseManifest 'Basic' -ModuleRoot 'c:\modules' } |
                    Should -Throw

                Should -Invoke Write-PSNowStructuredLog -ParameterFilter { $Status -eq 'retrying' } -Exactly 0 -Scope It
            }

            It 'propagates ParameterBindingException immediately when PSNOW_DISABLE_RETRY=true' {
                $env:PSNOW_DISABLE_RETRY = 'true'
                Mock Invoke-Plaster {
                    throw [System.Management.Automation.ParameterBindingException]::new(
                        "A parameter cannot be found that matches parameter name 'GitHubUserName'."
                    )
                }

                { New-PSNowModule -NewModuleName 'RetryFail' -BaseManifest 'Basic' -ModuleRoot 'c:\modules' } |
                    Should -Throw
            }

            It 'treats PSNOW_DISABLE_RETRY=0 as OFF and uses the retry loop' {
                $env:PSNOW_DISABLE_RETRY = '0'

                $null = New-PSNowModule -NewModuleName 'RetryZero' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'

                Should -Invoke Invoke-Plaster -Exactly 1 -Scope It
            }
        }
    }
}
