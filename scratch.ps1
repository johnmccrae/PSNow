$manifest = Import-PowerShellDataFile New-MyPSModule.psd1
[version]$version = $Manifest.ModuleVersion
# Add one to the build of the version number
[version]$NewVersion = "{0}.{1}.{2}" -f $Version.Major, $Version.Minor, ($Version.Build + 1) 
# Update the manifest file
Update-ModuleManifest -Path .\BeardAnalysis.psd1 -ModuleVersion $NewVersion




Import-Module .\New-MyPSModule.psm1

Get-Command -Module New-MyPSModule |
    Sort-Object Noun, Verb |
    New-MyPSModule `
    -Title 'Get-HelpAsMarkDown' `
    -Description 'PowerShell module for converting PowerShell help information to MarkDown' `
    -PrefacePath ./PREFACE.md | 
    Out-File .\README.md -Encoding utf8



Import-Module UncommonSense.PowerShell.Documentation -Force

Get-Command -Module New-MyPSModule |
    Sort-Object Noun, Verb |
    Convert-HelpToMarkDown `
    -Title 'New-MyPSModule' `
    -Description 'PowerShell module for creating PowerShell Modules' `
    -PrefacePath .\PREFACE.md | 
    Out-File .\README.md -Encoding utf8

