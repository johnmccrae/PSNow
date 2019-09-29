<#
    .SYNOPSIS

    Gets data from NASA at the url provided

    .DESCRIPTION

    This is a helper function designed to retrieve data at the designated url and ship it back to the calling app.

    .INPUTS

    Token

    .INPUTS

    URL

    .INPUTS

    PARAMETERS - a hashtable object that takes in any parameters associated with the url or calling function.

    .OUTPUTS

    System.Array


    .EXAMPLE

    PS> $foo = Get-Nasadata -url "https://api.nasa.gov/something-interesting$token"

    .LINK

    https://api.nasa.gov/index.html


#>
function Get-NASAData {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $token = $env:NasaKey,
        [Parameter(Mandatory=$true)]
        [System.String]
        $url = "",
        [Parameter(Mandatory=$false)]
        [System.Collections.Hashtable]
        $parameters
    )
    begin {
        #process parameters first, build the url with them, then invoke the restmethod
        $nasa_data = Invoke-RestMethod -Uri $url
        return $nasa_data
    }

}