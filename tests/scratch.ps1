$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*.psm1")
$moduleName = Split-Path $moduleRoot -Leaf


            
            Write-Output "Module Root is: " $moduleRoot
            Write-Output "Module Name is: " $moduleName