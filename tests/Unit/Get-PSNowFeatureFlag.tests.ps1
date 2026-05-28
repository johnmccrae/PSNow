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
    Describe 'Get-PSNowFeatureFlag' {
        AfterEach {
            # Clean up any env vars set during tests
            [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', $null)
            [System.Environment]::SetEnvironmentVariable('PSNOW_MY_FEATURE', $null)
        }

        Context 'default OFF behaviour' {
            It 'returns $false when the env var is not set' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', $null)
                Get-PSNowFeatureFlag -Name 'StrictLogSanitization' | Should -BeFalse
            }

            It 'returns $false when the env var is empty string' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', '')
                Get-PSNowFeatureFlag -Name 'StrictLogSanitization' | Should -BeFalse
            }
        }

        Context 'explicit ON values' {
            It 'returns $true when set to 1' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', '1')
                Get-PSNowFeatureFlag -Name 'StrictLogSanitization' | Should -BeTrue
            }

            It 'returns $true when set to true' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', 'true')
                Get-PSNowFeatureFlag -Name 'StrictLogSanitization' | Should -BeTrue
            }

            It 'returns $true when set to yes' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', 'yes')
                Get-PSNowFeatureFlag -Name 'StrictLogSanitization' | Should -BeTrue
            }
        }

        Context 'explicit OFF values' {
            It 'returns $false when set to 0' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', '0')
                Get-PSNowFeatureFlag -Name 'StrictLogSanitization' | Should -BeFalse
            }

            It 'returns $false when set to false' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', 'false')
                Get-PSNowFeatureFlag -Name 'StrictLogSanitization' | Should -BeFalse
            }

            It 'returns $false when set to no' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', 'no')
                Get-PSNowFeatureFlag -Name 'StrictLogSanitization' | Should -BeFalse
            }
        }

        Context 'env var naming convention' {
            It 'converts PascalCase to SCREAMING_SNAKE_CASE with PSNOW_ prefix' {
                [System.Environment]::SetEnvironmentVariable('PSNOW_MY_FEATURE', '0')
                Get-PSNowFeatureFlag -Name 'MyFeature' | Should -BeFalse
            }
        }
    }
}
