<#
.SYNOPSIS
Finds your PSNow created modules

.DESCRIPTION
When you use PSNow to create a module, it adds the name and location to a file called Currentmodules.txt. That list is returned to you here.

.EXAMPLE
Find-PSNowModule

There are no switches to execute here, you're just getting a list of modules returned to you.

.NOTES
General Notes
#>
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