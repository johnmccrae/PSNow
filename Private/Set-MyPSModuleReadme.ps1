Function Set-MyPSModuleReadme{
    [cmdletbinding()]

    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    $moduleName = Split-Path $projectRoot -Leaf

    if (-not (get-module UncommonSense.PowerShell.Documentation  )) {
        Install-Module -Name UncommonSense.PowerShell.Documentation -Repository PSGallery -Force
    }

    Import-Module UncommonSense.PowerShell.Documentation -Force

    Get-Command -Module $ModuleName |
        Sort-Object Noun, Verb |
        Convert-HelpToMarkDown `
        -Title "$ModuleName" `
        -Description '<your text goes here>' `
        -PrefacePath .\PREFACE.md |
        Out-File .\README.md -Encoding utf8

}
