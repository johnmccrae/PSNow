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

    # ---------------------------------------------------------------------------
    # Fix 1: ValidatePattern on $NewModuleName
    # Rationale: prevents path traversal and shell-injection via the module name,
    # which is used as a directory name. Pattern allows only safe PS module names.
    # ---------------------------------------------------------------------------
    Describe 'New-PSNowModule security: $NewModuleName ValidatePattern' {

        It 'rejects a name starting with a dot' {
            { New-PSNowModule -NewModuleName '.hidden' -BaseManifest 'Basic' } |
                Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'rejects a name containing a path separator (forward slash)' {
            { New-PSNowModule -NewModuleName 'evil/path' -BaseManifest 'Basic' } |
                Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'rejects a name containing a backslash' {
            { New-PSNowModule -NewModuleName 'evil\path' -BaseManifest 'Basic' } |
                Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'rejects a name containing dotdot traversal' {
            { New-PSNowModule -NewModuleName '../traversal' -BaseManifest 'Basic' } |
                Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'rejects a name exceeding 64 characters' {
            $longName = 'A' + ('x' * 64)   # 65 chars
            { New-PSNowModule -NewModuleName $longName -BaseManifest 'Basic' } |
                Should -Throw -ErrorId 'ParameterArgumentValidationError*'
        }

        It 'accepts a valid single-word module name' {
            Mock GetPSNowOs { 'Windows' }
            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-OldPSNowManifest {}
            Mock Invoke-PSNowPlasterSafely {}
            Mock Add-Content {}
            Mock Write-PSNowStructuredLog {}
            Mock Set-Item {}

            { New-PSNowModule -NewModuleName 'MyModule' -BaseManifest 'Basic' -ModuleRoot 'C:\temp' } |
                Should -Not -Throw
        }

        It 'accepts a name with hyphens, dots, and digits' {
            Mock GetPSNowOs { 'Windows' }
            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-OldPSNowManifest {}
            Mock Invoke-PSNowPlasterSafely {}
            Mock Add-Content {}
            Mock Write-PSNowStructuredLog {}
            Mock Set-Item {}

            { New-PSNowModule -NewModuleName 'Az.Compute2' -BaseManifest 'Basic' -ModuleRoot 'C:\temp' } |
                Should -Not -Throw
        }
    }

    # ---------------------------------------------------------------------------
    # Fix 2: ShouldProcess / -WhatIf support
    # Rationale: state-changing functions must support -WhatIf so operators can
    # perform dry runs before creating directories and files.
    # ---------------------------------------------------------------------------
    Describe 'New-PSNowModule security: ShouldProcess / -WhatIf' {

        BeforeEach {
            Mock GetPSNowOs { 'Windows' }
            Mock Set-Location {}
            Mock Test-Path { $false }
            Mock Remove-OldPSNowManifest {}
            Mock New-Item {}
            Mock Invoke-PSNowPlasterSafely {}
            Mock Add-Content {}
            Mock Write-PSNowStructuredLog {}
            Mock Set-Item {}
        }

        It 'supports -WhatIf without throwing' {
            { New-PSNowModule -NewModuleName 'WhatIfTest' -BaseManifest 'Basic' -ModuleRoot 'C:\temp' -WhatIf } |
                Should -Not -Throw
        }

        It 'does not call Invoke-PSNowPlasterSafely when -WhatIf is set' {
            New-PSNowModule -NewModuleName 'WhatIfTest' -BaseManifest 'Basic' -ModuleRoot 'C:\temp' -WhatIf
            Should -Invoke Invoke-PSNowPlasterSafely -Scope It -Times 0 -Exactly
        }

        It 'does not call Add-Content when -WhatIf is set' {
            New-PSNowModule -NewModuleName 'WhatIfTest' -BaseManifest 'Basic' -ModuleRoot 'C:\temp' -WhatIf
            Should -Invoke Add-Content -Scope It -Times 0 -Exactly
        }

        It 'does not call New-Item when -WhatIf is set' {
            New-PSNowModule -NewModuleName 'WhatIfTest' -BaseManifest 'Basic' -ModuleRoot 'C:\temp' -WhatIf
            Should -Invoke New-Item -Scope It -Times 0 -Exactly
        }
    }

    # ---------------------------------------------------------------------------
    # Fix 3: $ModuleRoot path canonicalization
    # Rationale: $ModuleRoot is user-supplied and unvalidated. A path containing
    # '..' sequences could resolve to an unintended location on disk. GetFullPath
    # collapses traversals before any directory or file operations run.
    # ---------------------------------------------------------------------------
    Describe 'New-PSNowModule security: $ModuleRoot canonicalization' {

        BeforeEach {
            Mock GetPSNowOs { 'Windows' }
            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-OldPSNowManifest {}
            Mock Invoke-PSNowPlasterSafely {}
            Mock Add-Content {}
            Mock Write-PSNowStructuredLog {}
            Mock Set-Item {}
        }

        It 'collapses dotdot sequences in a user-supplied ModuleRoot' {
            # Use an OS-native absolute path so GetFullPath can canonicalize it.
            # GetFullPath only fires when IsPathRooted is true on the current OS.
            $traversalPath = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                'C:\legitimate\..\safe'
            } else {
                '/tmp/PSNow-legitimate/../safe'
            }
            $script:capturedDest = $null
            Mock Invoke-PSNowPlasterSafely {
                param([hashtable]$PlasterParams)
                $script:capturedDest = $PlasterParams.Destination
            }

            New-PSNowModule -NewModuleName 'TraversalTest' -BaseManifest 'Basic' -ModuleRoot $traversalPath

            $script:capturedDest | Should -Not -Match '\.\.'
        }

        It 'accepts a straight absolute path unchanged' {
            $straightPath = if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                'C:\modules'
            } else {
                '/tmp/PSNow-modules'
            }
            $script:capturedDest = $null
            Mock Invoke-PSNowPlasterSafely {
                param([hashtable]$PlasterParams)
                $script:capturedDest = $PlasterParams.Destination
            }

            New-PSNowModule -NewModuleName 'StraightPath' -BaseManifest 'Basic' -ModuleRoot $straightPath

            $script:capturedDest | Should -Be $straightPath
        }
    }
}
