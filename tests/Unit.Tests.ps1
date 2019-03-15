$projectRoot = Resolve-Path "$PSScriptRoot\.."
# $moduleRoot = Split-Path (Resolve-Path "$projectRoot\*.psm1")
$moduleName = Split-Path $projectRoot -Leaf

Describe "Basic function unit tests" -Tags Build {

    It "Module '$moduleName' can import cleanly" {
        {Import-Module (Join-Path $projectRoot "$moduleName.psm1") -force } | Should Not Throw
    }

}
