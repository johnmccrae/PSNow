<#
.SYNOPSIS
Helper function to trim whitespace on all scripts in the local module structure

.DESCRIPTION
Helper function to trim whitespace on all scripts in the local module structure. The other option you have is to set the flag   "files.trimTrailingWhitespace": true   in your VSCode settings

.EXAMPLE
Write-ChefScriptNoWhitespace

.NOTES
General notes
#>

function Write-PSNowScriptNoWhitespace {
    [cmdletBinding()]
    Param
    (
    )

    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    $moduleRoot = Split-Path (Resolve-Path "$projectRoot\*.psm1")
    Set-Location $projectRoot

    $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse | Where-Object fullname -notmatch 'classes'
    # $scripts = Get-ChildItem -path (Get-Location -PSProvider FileSystem).ProviderPath -Include *.ps1, *.psm1, *.psd1 -Recurse | Where-Object fullname -notmatch 'classes'

    $scripts | ForEach-Object {
        (Get-Content $_ | ForEach-Object { $_.TrimEnd() }) |
        Set-Content $_
    }

}

