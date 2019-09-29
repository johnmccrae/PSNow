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
Import-Module -Name "$moduleroot$PathDivider$moduleName.psm1" -Force -ErrorAction Stop