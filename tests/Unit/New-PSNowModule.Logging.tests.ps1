Set-StrictMode -Version Latest

InModuleScope -ModuleName PSNow {
    Describe 'New-PSNowModule structured logging' {
        BeforeEach {
            $env:BHPathDivider = '\'

            Mock Get-Variable -ParameterFilter { $Name -eq 'PSVersionTable' -and $ValueOnly } -MockWith {
                @{ PSVersion = [Version]'5.1.0' }
            }

            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-Item {}
            Mock Get-ChildItem { [pscustomobject]@{ FullName = 'C:\localrepo\PSNow\PlasterTemplate\Basic.xml' } }
            Mock Copy-Item {}
            Mock New-Item {}
            Mock Write-Output {}
            Mock Add-Content {}
            Mock Write-Verbose {}
            Mock Invoke-Plaster {}
        }

        It 'emits started and completed verbose logs with consistent core fields' {
            $null = New-PSNowModule -NewModuleName 'LoggingDemo' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match '^\[op=invoke-plaster, status=started, elapsed_ms=0, module_name=LoggingDemo, manifest=Basic, destination=c:\\modules\]$'
            } -Exactly 1 -Scope It

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match '^\[op=invoke-plaster, status=completed, elapsed_ms=\d+, module_name=LoggingDemo, manifest=Basic, destination=c:\\modules\]$'
            } -Exactly 1 -Scope It
        }

        It 'emits a failed verbose log when Invoke-Plaster throws' {
            Mock Invoke-Plaster { throw 'plaster failed' }

            {
                New-PSNowModule -NewModuleName 'LoggingDemo' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'
            } | Should -Throw 'plaster failed'

            Should -Invoke Write-Verbose -ParameterFilter {
                $Message -match '^\[op=invoke-plaster, status=failed, elapsed_ms=\d+, module_name=LoggingDemo, manifest=Basic, destination=c:\\modules, error=plaster failed\]$'
            } -Exactly 1 -Scope It
        }
    }
}