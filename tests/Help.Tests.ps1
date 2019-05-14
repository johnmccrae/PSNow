# $projectRoot = Resolve-Path "$PSScriptRoot\.."
# $moduleRoot = Split-Path (Resolve-Path "$projectRoot\*.psm1")
$moduleRoot = Resolve-Path "$PSScriptRoot\.."
$moduleName = Split-Path $moduleRoot -Leaf


Describe "Help tests for $moduleName" -Tags Build {


    if(Get-Module -Name $moduleName){
        Remove-module $moduleName -force
    }
    Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

    $functions = Get-Command -Module $moduleName
    $help = $functions | ForEach-Object {Get-Help $_.name}

    if ($help.count){
        foreach($node in $help)
        {
            Context "checking help for $node.name" {

                it "has a description" {
                    $node.description | Should Not BeNullOrEmpty
                }
                it "has an example" {
                    $node.examples | Should Not BeNullOrEmpty
                }
                foreach($parameter in $node.parameters.parameter)
                {
                    if($parameter -notmatch 'whatif|confirm')
                    {
                        it "parameter $($parameter.name) has a description" {
                            $parameter.Description.text | Should Not BeNullOrEmpty
                        }
                    }
                }
            }
        }
    }
    else {
        Context "Checking help for $help.name" {
                it "has a description" {
                    $help.description | Should Not BeNullOrEmpty
                }
                it "has an example" {
                    $help.examples | Should Not BeNullOrEmpty
                }
                foreach($parameter in $help.parameters.parameter)
                {
                    if($parameter -notmatch 'whatif|confirm')
                    {
                        it "parameter $($parameter.name) has a description" {
                            $parameter.Description.text | Should Not BeNullOrEmpty
                        }
                    }
                }

        }
    }
}
