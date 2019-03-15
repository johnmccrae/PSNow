$moduleRoot = Resolve-Path "$PSScriptRoot\"
$moduleName = Split-Path $moduleRoot -Leaf
$testroot = (join-path $moduleRoot -ChildPath "tests")

set-location $testroot

Invoke-Pester

Set-location $moduleRoot

