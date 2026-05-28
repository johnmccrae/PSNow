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

    Describe 'Invoke-PSNowWithRetry' {

        BeforeEach {
            Mock Write-PSNowStructuredLog { }
            Mock Start-Sleep { }
        }

        Context 'succeeds on the first attempt' {

            It 'returns the result of the scriptblock' {
                $result = Invoke-PSNowWithRetry -OperationName 'test' -ScriptBlock { 42 }
                $result | Should -Be 42
            }

            It 'logs one attempt and one succeeded entry' {
                Invoke-PSNowWithRetry -OperationName 'test' -ScriptBlock { }
                Should -Invoke Write-PSNowStructuredLog -ParameterFilter { $Status -eq 'attempt' }   -Times 1 -Scope It
                Should -Invoke Write-PSNowStructuredLog -ParameterFilter { $Status -eq 'succeeded' } -Times 1 -Scope It
            }

            It 'does not sleep when no retry is needed' {
                Invoke-PSNowWithRetry -OperationName 'test' -ScriptBlock { }
                Should -Invoke Start-Sleep -Times 0 -Scope It
            }
        }

        Context 'retries on transient failure then succeeds' {

            It 'returns the result after the second attempt' {
                $script:callCount = 0
                $result = Invoke-PSNowWithRetry -OperationName 'test' -MaxAttempts 3 -InitialDelayMs 10 -ScriptBlock {
                    $script:callCount++
                    if ($script:callCount -lt 2) { throw 'transient' }
                    'ok'
                }
                $result       | Should -Be 'ok'
                $script:callCount | Should -Be 2
            }

            It 'logs error and retry for the failed attempt' {
                $script:callCount = 0
                Invoke-PSNowWithRetry -OperationName 'test' -MaxAttempts 3 -InitialDelayMs 10 -ScriptBlock {
                    $script:callCount++
                    if ($script:callCount -lt 2) { throw 'transient' }
                }
                Should -Invoke Write-PSNowStructuredLog -ParameterFilter { $Status -eq 'error' } -Times 1 -Scope It
                Should -Invoke Write-PSNowStructuredLog -ParameterFilter { $Status -eq 'retry' } -Times 1 -Scope It
                Should -Invoke Start-Sleep -Times 1 -Scope It
            }
        }

        Context 'exhausts all attempts' {

            It 'throws after MaxAttempts' {
                $script:callCount = 0
                {
                    Invoke-PSNowWithRetry -OperationName 'test' -MaxAttempts 3 -InitialDelayMs 10 -ScriptBlock {
                        $script:callCount++
                        throw 'always fails'
                    }
                } | Should -Throw
                $script:callCount | Should -Be 3
            }

            It 'logs a failed entry after all attempts are exhausted' {
                {
                    Invoke-PSNowWithRetry -OperationName 'test' -MaxAttempts 2 -InitialDelayMs 10 -ScriptBlock {
                        throw 'fail'
                    }
                } | Should -Throw
                Should -Invoke Write-PSNowStructuredLog -ParameterFilter { $Status -eq 'failed' } -Times 1 -Scope It
            }
        }

        Context 'exponential backoff' {

            It 'doubles the delay on each successive retry' {
                {
                    Invoke-PSNowWithRetry -OperationName 'test' -MaxAttempts 3 -InitialDelayMs 100 -BackoffMultiplier 2.0 -ScriptBlock {
                        throw 'fail'
                    }
                } | Should -Throw
                # First retry: 100 ms; second retry: 200 ms.
                Should -Invoke Write-PSNowStructuredLog -ParameterFilter {
                    $Status -eq 'retry' -and $Fields['delay_ms'] -eq 100
                } -Times 1 -Scope It
                Should -Invoke Write-PSNowStructuredLog -ParameterFilter {
                    $Status -eq 'retry' -and $Fields['delay_ms'] -eq 200
                } -Times 1 -Scope It
            }
        }

        Context 'timeout budget enforcement' {

            It 'throws TimeoutException when budget is exceeded before sleep' {
                # TimeoutSeconds = 0.001 (1 ms). PowerShell function call overhead
                # reliably exceeds 1 ms, so the post-failure timeout check fires.
                {
                    Invoke-PSNowWithRetry -OperationName 'test' -MaxAttempts 5 `
                        -InitialDelayMs 5000 -TimeoutSeconds 0.001 -ScriptBlock {
                        throw 'transient'
                    }
                } | Should -Throw -ExceptionType ([System.TimeoutException])
            }

            It 'logs a timeout entry when budget is exceeded' {
                {
                    Invoke-PSNowWithRetry -OperationName 'test' -MaxAttempts 5 `
                        -InitialDelayMs 5000 -TimeoutSeconds 0.001 -ScriptBlock {
                        throw 'transient'
                    }
                } | Should -Throw
                Should -Invoke Write-PSNowStructuredLog -ParameterFilter { $Status -eq 'timeout' } -Times 1 -Scope It
            }
        }
    }

    Describe 'Remove-OldPSNowManifest resilience' {

        BeforeEach {
            Mock Test-Path   { $false }
            Mock Remove-Item { }
            Mock Write-PSNowStructuredLog { }
            Mock Start-Sleep { }
        }

        It 'retries Copy-Item on transient failure and succeeds on the second attempt' {
            $script:copyCount = 0
            Mock Copy-Item {
                $script:copyCount++
                if ($script:copyCount -lt 2) { throw [System.IO.IOException]::new('file locked') }
            }
            { Remove-OldPSNowManifest -TemplateRoot '/psnow-test' -BaseManifest 'Basic' } | Should -Not -Throw
            $script:copyCount | Should -Be 2
        }

        It 'propagates Copy-Item failure after MaxAttempts' {
            Mock Copy-Item { throw [System.IO.IOException]::new('file locked') }
            { Remove-OldPSNowManifest -TemplateRoot '/psnow-test' -BaseManifest 'Basic' } | Should -Throw
        }
    }

    Describe 'New-PSNowModule tracker-append resilience' {

        BeforeEach {
            Mock GetPSNowOs              { 'Linux' }
            Mock Get-PSNowTempDirectory  { '/tmp' }
            Mock Remove-OldPSNowManifest { }
            Mock Invoke-PSNowPlasterSafely { }
            Mock Test-Path               { $true }
            Mock New-Item                { }
            Mock Set-Location            { }
            Mock Get-Location            { [pscustomobject]@{ Path = '/psnow-test' } }
            Mock Write-PSNowStructuredLog { }
            Mock Start-Sleep             { }
        }

        It 'retries Add-Content on transient failure and succeeds' {
            $script:appendCount = 0
            Mock Add-Content {
                $script:appendCount++
                if ($script:appendCount -lt 2) { throw [System.IO.IOException]::new('file locked') }
            }
            New-PSNowModule -NewModuleName 'MyMod' -BaseManifest 'Basic' -ModuleRoot '/tmp/mods'
            $script:appendCount | Should -Be 2
        }
    }

    Describe 'Find-PSNowModule tracker-read resilience' {

        BeforeEach {
            Mock Write-PSNowStructuredLog { }
            Mock Start-Sleep             { }
        }

        It 'retries Get-Content on transient failure and returns modules' {
            $script:readCount = 0
            Mock Test-Path   { $true }
            Mock Write-Output { }
            Mock Get-Content {
                $script:readCount++
                if ($script:readCount -lt 2) { throw [System.IO.IOException]::new('file locked') }
                '/tmp/mods/MyMod'
            }
            { Find-PSNowModule } | Should -Not -Throw
            $script:readCount | Should -Be 2
        }
    }
}

