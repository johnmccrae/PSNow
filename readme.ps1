Import-Module UncommonSense.PowerShell.Documentation -Force

Get-Command -Module New-MyPSModule |
    Sort-Object Noun, Verb |
    Convert-HelpToMarkDown `
    -Title 'New-MyPSModule' `
    -Description 'PowerShell module for creating PowerShell Modules' `
    -PrefacePath .\PREFACE.md | 
    Out-File .\README.md -Encoding utf8
