# http://wahlnetwork.com/2016/11/28/building-powershell-unit-tests-pester-using-mock-commands/
# https://github.com/pester/Pester/wiki/Mocking-with-Pester

<#
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#>


$Here =  Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ThisModule =  ($MyInvocation.MyCommand.Name -replace '.ps1').Split('.')[0]

if ($PSVersionTable.PSEdition -eq "Desktop") {
    $PathDivider = "\"
}
elseif ($PSVersionTable.PSEdition -eq "Core") {

    if (($isMACOS) -or ($isLinux)) {
        $PathDivider = "/"
    }
}
else {
    $PathDivider = "\"
}

Get-Module -ListAvailable -Name $ThisModule -All | Remove-Module -Force -ErrorAction Ignore
Import-Module -Name "$Here$PathDivider$ThisModule.psm1" -Force -ErrorAction Stop

Describe -Name 'The NASA module structure' {

    Context -Name 'Basic Module Setup' {

        It 'Has a valid root module' {
            (Test-Path -path "$Here$PathDivider$ThisModule.psm1") | Should be $true
        }

        It 'Has a valid module manifest' {

            # do I have a psd1 file
            (Test-Path -path "$Here$PathDivider$ThisModule.psd1") | Should be $true

            # does it contain a proper reference to the psm1
            "$Here$PathDivider$ThisModule.psd1" | Should FileContentMatch "$ThisModule.psm1"

            # Finally, run the built in function to test the manifest structure overall
            Test-ModuleManifest -Path "$Here$PathDivider$ThisModule.psd1"
        }

        It "$ThisModule has public folder functions" {
            $("$here$PathDivider" + "Public" + "$PathDivider*.ps1") | Should Exist
        }

        It "The $ThisModule psm1 file should be valid code" {
            $psmfile = Get-Content -Path "$Here$PathDivider$ThisModule.psm1" -ErrorAction Stop

            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psmfile, [ref]$errors)
            $errors.count | Should Be 0
        }

    }

    Context -Name "There is a valid API Token" {
        It '$env:NasaKey should not be null' {
            $env:NasaKey | Should Not BeNullOrEmpty
        }
    }

    $manifest = Import-PowerShellDataFile "$Here$PathDivider$ThisModule.psd1"
    foreach ($nasafunction in $manifest.FunctionsToExport) {
        Context -Name "Testing $nasafunction" {
            It "The function [$nasafunction] should exist in the public folder" {
                    "$Here$PathDivider" + "Public" + "$PathDivider$nasafunction.ps1" | Should Exist
            }

            It "$nasafunction should be an Advanced Function" {
                "$Here$PathDivider" + "Public" + "$PathDivider$nasafunction.ps1" | Should FileContentMatch 'function'
                "$Here$PathDivider" + "Public" + "$PathDivider$nasafunction.ps1" | Should FileContentMatch 'cmdletbinding'
                "$Here$PathDivider" + "Public" + "$PathDivider$nasafunction.ps1" | Should FileContentMatch 'param'
            }

            It "The $nasafunction ps1 file should be valid code" {
                $path = "$Here$PathDivider" + "Public" + "$PathDivider$nasafunction.ps1"
                $psfile = Get-Content -Path $path  -ErrorAction Stop

                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($psfile, [ref]$errors)
                $errors.count | Should Be 0
            }

            Describe -Name "Checking Help for $nasafunction"{
            $help = Get-Help $nasafunction

                It 'Should not be auto-generated' {
                    $help.Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
                }

                # Should be a description for every function
                It "Gets description for $nasafunction" {
                    $help.Description | Should Not BeNullOrEmpty
                }

                # Should be at least one example
                It "Gets example code from $nasafunction" {
                    ($help.Examples.Example | Select-Object -First 1).Code | Should Not BeNullOrEmpty
                }

                # Should be at least one example description
                It "Gets example help from $nasafunction" {
                    ($help.Examples.Example.Remarks | Select-Object -First 1).Text | Should Not BeNullOrEmpty
                }

            }

            Describe -Name "Verifying Function test files"{
                It "$nasafunction.tests.ps1 Should exist"{
                    "$Here$PathDivider" + "Tests" + "$PathDivider$nasafunction.tests.ps1" | Should Exist
                }
            }

        }
    }

}
