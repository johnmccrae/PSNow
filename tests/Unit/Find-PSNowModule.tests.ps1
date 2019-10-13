$moduleName = $Env:BHProjectName
$moduleroot = $Env:BHModulePath

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

Get-Module -ListAvailable -Name $moduleName -All | Remove-Module -Force -ErrorAction Ignore
Import-Module -Name "$moduleroot$PathDivider$moduleName.psd1" -Force -ErrorAction Stop

Describe -Name "Does the Find Function Work" -tags Build {

    Mock Find-PSNowModule -MockWith {return 'C:\modules\test6'}

    It "It should return a list of directories"{
        Mock  Find-PSNowModule -MockWith { return 'C:\modules\testing7'}
        $wascalled = 1
        Assert-MockCalled -CommandName Find-PSNowModule $wascalled
    }

    It "It should have valid paths in it"{

        #$foo = Get-Item -Path Currentmodules.txt | Get-Content

        #$directories = Get-Content Currentmodules.txt


        #foreach($directory in $directories){


        #}



    }
}