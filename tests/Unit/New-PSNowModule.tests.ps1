#$moduleName = $Env:BHProjectName
$moduleroot = $Env:BHModulePath


Describe -Name "New-PSNowModule Tests" {

    It "The New-PSNowModule Script Should Exist"{
        $psnowroot = (get-item $moduleroot).parent.parent.FullName
        $functionpath = $($psnowroot + $env:BHPathDivider + 'Public' + $env:BHPathDivider + 'New-PSNowModule.ps1')
        [bool]$goodpath = Test-Path $functionpath
        $goodpath | Should -BeTrue
    }

    It 'It should accept 3 parameters'{
        Mock New-PSNowModule -ParameterFilter { $NewModuleName -eq 'Testing' -and $BaseManifest -eq 'Advanced' -and $ModuleRoot -eq 'c:\modules' } -MockWith { $true }
        $null = New-PSNowModule -NewModuleName 'testing' -BaseManifest 'Advanced' -ModuleRoot 'c:\modules'
        Assert-MockCalled New-PSNowModule -ParameterFilter { $NewModuleName -eq 'Testing' -and $BaseManifest -eq 'Advanced' -and $ModuleRoot -eq 'c:\modules' } -Exactly 1 -Scope It
    }

}

