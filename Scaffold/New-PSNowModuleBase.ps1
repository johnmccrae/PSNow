<#
.SYNOPSIS
A module created by me that does a thing.

.DESCRIPTION
This module uses all these marvelous technologies to do great things

.PARAMETER Parameter1
A parameter for your module

.PARAMETER Parameter2
A second parameter

.EXAMPLE
Mymodule -myparameter1 -myparameter2

.NOTES
Go here for more details - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-6


#>

function New-PSNow {

    [CmdletBinding()]
    param (

    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {

    }
    end {

    }

}

Export-ModuleMember -Function new-myposmodule
