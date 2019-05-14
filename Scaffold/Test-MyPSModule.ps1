
Function Test-MyPSModule {
    [cmdletbinding()]
    param()

    begin{
        $moduleRoot = Resolve-Path "$PSScriptRoot\"
        # $moduleName = Split-Path $moduleRoot -Leaf
        $testroot = (join-path $moduleRoot -ChildPath "tests")

    }
    Process{



        set-location $testroot

        Invoke-Pester

        Set-location $moduleRoot

    }


}


