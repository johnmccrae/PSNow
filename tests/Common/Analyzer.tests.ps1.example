# PSScriptAnalyzer - ignore creation of a SecureString using plain text for the contents of this script file
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*.psm1")
#$moduleName = Split-Path $moduleRoot -Leaf


Describe "PSScriptAnalyzer rule-sets" -Tag Build {

    Context "Ensuring all scripts wll correctly pass Analysis" {

        if (-not (Get-Module -Name PSScriptAnalyzer)) {
            install-module -Name PSScriptAnalyzer -Force -Verbose -Scope CurrentUser
        }

        $Rules = Get-ScriptAnalyzerRule
        $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse | Where-Object fullname -notmatch 'classes'

        foreach ( $Script in $scripts ) {
            Context "Script '$($script.FullName)'" {

                foreach ( $rule in $rules ) {
                    It "Rule [$rule]" {
                        (Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule.RuleName -ExcludeRule "PSAvoidusingconverttosecurestringwithplaintext" ).Count | Should Be 0
                    }
                }
            }
        }
    }
}
