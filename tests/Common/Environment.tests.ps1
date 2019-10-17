Set-StrictMode -Version Latest

InModuleScope -ModuleName PSNow {
    Describe 'GetPSNowPsVersion' {
        It 'Returns value of $PSVersionTable.PsVersion.Major' {
            Mock Get-Variable -ParameterFilter { $Name -eq 'PSVersionTable' -and $ValueOnly } -MockWIth {
                @{ PSVersion = [Version]'5.0.0' }
            }

            GetPSNowPsVersion | Should -Be 5
        }
    }

    # these tests mock GetPSNowOs on which It and Context depend
    # for figuring out if TestRegistry should be used, so keep the mocks
    # inside of It blocks otherwise the framework thinks we are on windows and
    # tries to activate TestRegistry on Linux which fails, because there are no registry
    Describe "GetPSNowOs" {
        Context "Windows with PowerShell 5 and lower" {
            It "Returns 'Windows' when PowerShell version is lower than 6" {
                Mock GetPSNowPsVersion { 5 }

                GetPSNowOs | Should -Be 'Windows'
            }
        }

        Context "Windows with PowerShell 6 and higher" {
            It "Returns 'Windows' when `$IsWindows is `$true and powershell version is 6 or higher" {

                Mock Get-Variable -ParameterFilter { $Name -eq 'IsWindows' -and $ValueOnly } -MockWith { $true }
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsLinux' -and $ValueOnly } -MockWith { $false }
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsMacOS' -and $ValueOnly } -MockWith { $false }
                Mock GetPSNowPsVersion { 6 }

                GetPSNowOs | Should -Be 'Windows'
            }

            It "Uses Get-Variable to retrieve IsWindows" {
                # IsWindows is a constant and cannot be overwritten, so check that we are using
                # Get-Variable to access its value, which allows us to mock it easily without
                # depending on the OS, same for IsLinux and IsMacOS

                Mock Get-Variable -ParameterFilter { $Name -eq 'IsWindows' -and $ValueOnly } -MockWith { $true }
                Mock GetPSNowPsVersion { 6 }

                $null = GetPSNowOs

                Assert-MockCalled Get-Variable -ParameterFilter { $Name -eq 'IsWindows' -and ($ValueOnly) } -Exactly 1 -Scope It
            }
        }

        Context "Linux with PowerShell 6 and higher" {
            It "Returns 'Linux' when `$IsLinux is `$true and powershell version is 6 or higher" {
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsWindows' -and $ValueOnly } -MockWith { $false }
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsLinux' -and $ValueOnly } -MockWith { $true }
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsMacOS' -and $ValueOnly } -MockWith { $false }
                Mock GetPSNowPsVersion { 6 }

                GetPSNowOs | Should -Be 'Linux'
            }

            It "Uses Get-Variable to retrieve IsLinux" {
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsLinux' -and $ValueOnly } -MockWith { $true }
                Mock GetPSNowPsVersion { 6 }

                $null = GetPSNowOs

                Assert-MockCalled Get-Variable -ParameterFilter { $Name -eq 'IsLinux' -and $ValueOnly } -Exactly 1 -Scope It
            }
        }

        Context "macOS with PowerShell 6 and higher" {
            It "Returns 'OSX' when `$IsMacOS is `$true and powershell version is 6 or higher" {
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsWindows' -and $ValueOnly } -MockWith { $false }
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsLinux' -and $ValueOnly } -MockWith { $false }
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsMacOS' -and $ValueOnly } -MockWith { $true }
                Mock GetPSNowPsVersion { 6 }

                GetPSNowOs | Should -Be 'macOS'
            }

            It "Uses Get-Variable to retrieve IsMacOS" {
                Mock Get-Variable -ParameterFilter { $Name -eq 'IsMacOS' -and $ValueOnly } -MockWith { $true }

                $null = GetPSNowOs

                Assert-MockCalled Get-Variable -ParameterFilter { $Name -eq 'IsMacOS' -and $ValueOnly } -Exactly 1 -Scope It
            }
        }
    }


    Describe 'Get-PSNowTempDirectory' {
        It 'returns the correct temp directory for Windows' -Skip:((GetPSNowOs) -ne 'Windows') {
            $expected = [System.IO.Path]::GetTempPath()

            $temp = Get-PSNowTempDirectory
            $temp | Should -Not -BeNullOrEmpty
            $temp | Should -Be $expected
        }

        It "returns '/private/tmp' directory for MacOS" {
            Mock 'GetPSNowOs' {
                'MacOS'
            }
            Get-PSNowTempDirectory | Should -Be '/private/tmp'
        }

        It "returns '/tmp' directory for Linux" -Skip:((GetPSNowOs) -ne 'Linux') {
            Mock 'GetPSNowOs' {
                'Linux'
            }
            Get-PSNowTempDirectory | Should -Be '/tmp'
        }
    }

    if ('Windows' -eq (GetPSNowOs)) {
        Describe 'Get-PSNowTempRegistry' {
            Mock 'GetPSNowOs' {
                return 'Windows'
            }

            It 'return the corret temp registry for Windows' {

                $expected = 'Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Software\PSNow'
                $tempPath = Get-PSNowTempRegistry
                $tempPath | Should -Be $expected
            }
        }
    }
}