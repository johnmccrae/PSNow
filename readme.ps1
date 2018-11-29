Import-Module Get-HelpAsMarkDown -Force

Get-Command -Module Get-HelpAsMarkDown |
    Sort-Object Noun, Verb |
    Get-HelpAsMarkDown `
    -Title 'Get-HelpAsMarkDown' `
    -Description 'PowerShell module for converting PowerShell help information to MarkDown' `
    -PrefacePath ./PREFACE.md | 
    Out-File .\README.md -Encoding utf8
