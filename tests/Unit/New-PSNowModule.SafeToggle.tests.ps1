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
    Describe 'New-PSNowModule safe toggle' {
        BeforeEach {
            Remove-Item Env:PSNOW_SAFE_MODE -ErrorAction SilentlyContinue
            $env:BHPathDivider = [System.IO.Path]::DirectorySeparatorChar

            Mock Get-Variable -ParameterFilter { $Name -eq 'PSVersionTable' -and $ValueOnly } -MockWith {
                @{ PSVersion = [Version]'5.1.0' }
            }

            Mock Set-Location {}
            Mock Test-Path { $true }
            Mock Remove-Item {}
            Mock Get-ChildItem { [pscustomobject]@{ FullName = 'C:\localrepo\PSNow\PlasterTemplate\Basic.xml' } }
            Mock New-Item {}
            Mock Add-Content {}
            Mock Copy-Item {}
            Mock Write-Verbose {}
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

                [void]$TemplatePath
                [void]$Destination
                [void]$ModuleName
                [void]$GitHubUserName
                [void]$PowerShellVersion
                [void]$Force
                [void]$Verbose
            }

            Mock Write-Output {}
        }

        AfterEach {
            Remove-Item Env:PSNOW_SAFE_MODE -ErrorAction SilentlyContinue
        }

        It 'writes module path output when safe mode is OFF' {
            $null = New-PSNowModule -NewModuleName 'SafeOff' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'

            Should -Invoke Write-Output -ParameterFilter { $InputObject -match 'Your module was built at:' } -Exactly 1 -Scope It
        }

        It 'suppresses module path output when safe mode is ON' {
            $env:PSNOW_SAFE_MODE = '1'

            $null = New-PSNowModule -NewModuleName 'SafeOn' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'

            Should -Invoke Write-Output -ParameterFilter { $InputObject -match 'Your module was built at:' } -Exactly 0 -Scope It
        }

        It 'writes module path output when safe mode is explicitly OFF' {
            $env:PSNOW_SAFE_MODE = '0'

            $null = New-PSNowModule -NewModuleName 'SafeZero' -BaseManifest 'Basic' -ModuleRoot 'c:\modules'

            Should -Invoke Write-Output -ParameterFilter { $InputObject -match 'Your module was built at:' } -Exactly 1 -Scope It
        }
    }
}
