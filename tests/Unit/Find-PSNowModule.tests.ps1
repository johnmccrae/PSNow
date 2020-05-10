#$moduleName = $Env:BHProjectName
$moduleroot = $Env:BHModulePath


Describe -Name "Does the Find Function Work" -tags Build {

    It "The Find-PSNowModule Script Should Exist" {
        $psnowroot = (get-item $moduleroot).parent.parent.FullName
        $functionpath = $($psnowroot + $env:BHPathDivider + 'Public' + $env:BHPathDivider + 'Find-PSNowModule.ps1')
        [bool]$goodpath = Test-Path $functionpath
        $goodpath | Should -BeTrue
    }

    It "It should locate the CurrentModules.txt file"{
        $psnowroot = (get-item $moduleroot).parent.parent.FullName
        $testpath = $($psnowroot + $env:BHPathDivider + '.\Currentmodules.txt')
        Test-Path $testpath | Should -not -BeFalse
    }

    It "It should return a list of directories"{
        Mock Find-PSNowModule -MockWith { return 'C:\modules\test6' }
        $results = Find-PSNowModule
        $results | Should -not -BeNullOrEmpty
    }

    It "It should have valid paths in it regardless of the OS"{
        $psnowroot = (get-item $moduleroot).parent.parent.FullName
        $modulespath = $($psnowroot + $env:BHPathDivider + 'Currentmodules.txt')
        $modules = Get-Content -Path $modulespath
        if($null -ne $modules){
            foreach($module in $modules){
                [bool]$goodpath = Test-Path $module
                $goodpath | Should -BeTrue
            }
        }
    }

}