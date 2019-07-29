$moduleName = $Env:BHProjectName
$moduleroot = $ENV:BHModulePath

Describe "Basic function unit tests" -Tags Build {

    It "Module '$moduleName' can import cleanly" {
        {Import-Module (Join-Path $moduleroot "$moduleName.psm1") -force } | Should Not Throw
    }

}
