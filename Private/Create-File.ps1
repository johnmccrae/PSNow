<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Path
Parameter description

.PARAMETER Name
Parameter description

.PARAMETER Content
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

function Create-File {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Content = ""
    )

    if (-not (& Test-Path -Path $Path)) {
        & New-Item -ItemType Directory -Path $Path | & Out-Null
    }

    $FullPath = & Join-Path -Path $Path -ChildPath $Name
    if (-not (& Test-Path -Path $FullPath)) {
        & Set-Content -Path  $FullPath -Value $Content -Encoding UTF8
        & Get-Item -Path $FullPath
    }
    else {
        # This is deliberately not sent through $SafeCommands, because our own tests rely on
        # mocking Write-Warning, and it's not really the end of the world if this call happens to
        # be screwed up in an edge case.
        Write-Warning "Skipping the file '$FullPath', because it already exists."
    }

    # In the plaster manifest - any item that begins PLASTER_PARAM_somename is 'somename' from the <parameters> section

}