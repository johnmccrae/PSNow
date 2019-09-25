$Here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ThisModule = Split-Path -Leaf $Here

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

Get-Module -ListAvailable -Name $ThisModule -All | Remove-Module -Force -ErrorAction Ignore
Import-Module -Name "$Here$PathDivider$ThisModule.psd1" -Force -ErrorAction Stop

 $picdata = Get-NASAPicOfTheDay

 $picdata | Export-Clixml "$Here\APODData.xml"