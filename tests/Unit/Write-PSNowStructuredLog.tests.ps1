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
    Describe 'Write-PSNowStructuredLog strict sanitization feature flag' {
        BeforeAll {
            # Capture the verbose message written by the function
            $script:capturedMessage = $null
        }

        AfterEach {
            [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', $null)
            $script:capturedMessage = $null
        }

        Context 'FLAG OFF (default) — raw concatenation preserved' {
            BeforeEach {
                # Ensure env var is unset — OFF is the default when no env var is present
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', $null)
            }

            It 'emits clean values without quoting' {
                Mock Write-Verbose { $script:capturedMessage = $Message }

                Write-PSNowStructuredLog -Operation 'test-op' -Status 'started' -Fields ([ordered]@{
                    path = '/simple/path'
                })

                $script:capturedMessage | Should -Be '[op=test-op, status=started, path=/simple/path]'
            }

            It 'does NOT quote values containing spaces when flag is OFF' {
                Mock Write-Verbose { $script:capturedMessage = $Message }

                Write-PSNowStructuredLog -Operation 'test-op' -Status 'started' -Fields ([ordered]@{
                    path = '/path with spaces'
                })

                $script:capturedMessage | Should -Be '[op=test-op, status=started, path=/path with spaces]'
                $script:capturedMessage | Should -Not -Match '"'
            }
        }

        Context 'FLAG ON — delimiter sanitization active' {
            BeforeEach {
                [System.Environment]::SetEnvironmentVariable('PSNOW_STRICT_LOG_SANITIZATION', '1')
            }

            It 'quotes a value containing spaces' {
                Mock Write-Verbose { $script:capturedMessage = $Message }

                Write-PSNowStructuredLog -Operation 'test-op' -Status 'started' -Fields ([ordered]@{
                    path = '/path with spaces'
                })

                $script:capturedMessage | Should -Match 'path="/path with spaces"'
            }

            It 'quotes a value containing a comma' {
                Mock Write-Verbose { $script:capturedMessage = $Message }

                Write-PSNowStructuredLog -Operation 'test-op' -Status 'done' -Fields ([ordered]@{
                    tags = 'a,b,c'
                })

                $script:capturedMessage | Should -Match 'tags="a,b,c"'
            }

            It 'quotes a value containing an equals sign' {
                Mock Write-Verbose { $script:capturedMessage = $Message }

                Write-PSNowStructuredLog -Operation 'test-op' -Status 'done' -Fields ([ordered]@{
                    expr = 'x=1'
                })

                $script:capturedMessage | Should -Match 'expr="x=1"'
            }

            It 'quotes a value containing a closing bracket' {
                Mock Write-Verbose { $script:capturedMessage = $Message }

                Write-PSNowStructuredLog -Operation 'test-op' -Status 'done' -Fields ([ordered]@{
                    note = 'end]here'
                })

                $script:capturedMessage | Should -Match 'note="end\]here"'
            }

            It 'does NOT quote a clean value when flag is ON' {
                Mock Write-Verbose { $script:capturedMessage = $Message }

                Write-PSNowStructuredLog -Operation 'test-op' -Status 'completed' -Fields ([ordered]@{
                    count = '3'
                })

                $script:capturedMessage | Should -Be '[op=test-op, status=completed, count=3]'
                $script:capturedMessage | Should -Not -Match '"'
            }
        }
    }
}
