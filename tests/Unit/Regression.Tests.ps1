$moduleRoot = $Env:BHModulePath
$moduleName = $Env:BHProjectName

Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

Describe "Regression tests" -Tag Build {

    Context "Github Issues" {

    }
}
