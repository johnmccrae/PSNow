function Find-PSNowModule {

    [CmdletBinding()]
    param (
    )

    begin {
        $ErrorActionPreference = 'Continue'
    }

    process{
        Write-Output "Here's your list of PSNow Modules"
        Write-Output "---------------------------------"
        Write-Output "`n"

        $templateroot = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

        $thefile = Get-ChildItem -path $templateroot -Include "currentmodules.txt"
        $modules = Get-Content -Path $thefile
        foreach($module in $modules){
            Write-Output $module
        }

    }
}