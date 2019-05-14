Function initialize-readme{
    [cmdletbinding()]

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleName = Split-Path $projectRoot -Leaf

Import-Module UncommonSense.PowerShell.Documentation -Force

Get-Command -Module <%= $PLASTER_PARAM_ModuleName %> |
    Sort-Object Noun, Verb |
    Convert-HelpToMarkDown `
    -Title <%= $PLASTER_PARAM_ModuleName %> `
    -Description '<your text goes here>' `
    -PrefacePath .\PREFACE.md | 
    Out-File .\README.md -Encoding utf8
}