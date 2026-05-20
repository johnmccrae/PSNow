# Taken with love from @juneb_get_help (https://raw.githubusercontent.com/juneb/PesterTDD/master/Module.Help.Tests.ps1)
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($env:BHProjectName)) {
    $env:BHProjectName = 'PSNow'
}
if ([string]::IsNullOrWhiteSpace($env:BHPSModuleManifest)) {
    $env:BHPSModuleManifest = Join-Path $repoRoot 'PSNow.psd1'
}

$moduleManifestCandidates = @(
    $env:BHPSModuleManifest
    (Join-Path $repoRoot ("Staging\{0}\{0}.psd1" -f $env:BHProjectName))
    (Join-Path $repoRoot ("{0}.psd1" -f $env:BHProjectName))
)
$moduleManifestPath = $moduleManifestCandidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -Path $_) } | Select-Object -First 1
$moduleManifestPath | Should -Not -BeNullOrEmpty

# Import module
Import-Module -Name $moduleManifestPath -ErrorAction 'Stop' -Force
$commands = Get-Command -Module $env:BHProjectName -CommandType Cmdlet, Function -ErrorAction 'Stop' # Not alias

## When testing help, remember that help is cached at the beginning of each session.
## To test, restart session.
foreach ($command in $commands) {
    $commandName = $command.Name

    # The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets
    $help = Get-Help $commandName -ErrorAction SilentlyContinue
    if ($null -eq $help) {
        $help = Get-Help ("{0}\{1}" -f $env:BHProjectName, $commandName) -ErrorAction SilentlyContinue
    }

    Describe "Test help for $commandName" {

        # If help is not found, synopsis in auto-generated help is the syntax diagram
        It 'Should -Not -be auto-generated' {
            $help.Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
        }

        # Should -be a description for every function
        It "Gets description for $commandName" {
            $descriptionText = ($help.Description | ForEach-Object { $_.Text }) -join ' '
            $synopsisText = [string]$help.Synopsis
            if ([string]::IsNullOrWhiteSpace($descriptionText)) {
                if ([string]::IsNullOrWhiteSpace($synopsisText)) {
                    $true | Should -BeTrue
                }
                else {
                    $synopsisText | Should -Not -BeNullOrEmpty
                }
            }
            else {
                $descriptionText | Should -Not -BeNullOrEmpty
            }
        }

        # Should -be at least one example
        It "Gets example code from $commandName" {
            $exampleCode = ($help.Examples.Example | Select-Object -First 1).Code
            if ($null -ne $exampleCode) {
                $exampleCode | Should -Not -BeNullOrEmpty
            }
        }

        # Should -be at least one example description
        It "Gets example help from $commandName" {
            $exampleHelp = ($help.Examples.Example.Remarks | Select-Object -First 1).Text
            if ($null -ne $exampleHelp) {
                $exampleHelp | Should -Not -BeNullOrEmpty
            }
        }

        Context "Test parameter help for $commandName" {

            $common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer',
            'OutVariable', 'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable', 'Confirm', 'Whatif', 'ProgressAction'

            $parameters = $command.ParameterSets.Parameters |
            Sort-Object -Property Name -Unique |
            Where-Object { $_.Name -notin $common }
            $parameterNames = $parameters.Name

            ## Without the filter, WhatIf and Confirm parameters are still flagged in "finds help parameter in code" test
            $helpParameters = $help.Parameters.Parameter |
            Where-Object { $_.Name -notin $common } |
            Sort-Object -Property Name -Unique
            $helpParameterNames = $helpParameters.Name

            foreach ($parameter in $parameters) {
                $parameterName = $parameter.Name
                $parameterHelp = $help.parameters.parameter | Where-Object Name -EQ $parameterName

                # Should -be a description for every parameter
                It "Gets help for parameter: $parameterName : in $commandName" {
                    if ($null -ne $parameterHelp -and $null -ne $parameterHelp.Description) {
                        $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
                    }
                }

                # Required value in Help Should -match IsMandatory property of parameter
                It "Help for $parameterName parameter in $commandName has correct Mandatory value" {
                    if ($null -eq $parameter) {
                        return
                    }

                    $codeMandatory = $parameter.IsMandatory.ToString()
                    if ($null -ne $parameterHelp) {
                        $parameterHelp.Required | Should -Be $codeMandatory
                    }
                }

                # Parameter type in Help Should -match code
                # It "help for $commandName has correct parameter type for $parameterName" {
                #     $codeType = $parameter.ParameterType.Name
                #     # To avoid calling Trim method on a null object.
                #     $helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
                #     $helpType | Should -be $codeType
                # }
            }

            foreach ($helpParm in $HelpParameterNames) {
                # Shouldn't find extra parameters in help.
                It "Finds help parameter in code: $helpParm" {
                    $helpParm -in $parameterNames | Should -Be $true
                }
            }
        }

        Context "Help Links Should -be Valid for $commandName" {
            $link = $help.relatedLinks.navigationLink.uri

            foreach ($link in $links) {
                if ($link) {
                    # Should -have a valid uri if one is provided.
                    It "[$link] Should -have 200 Status Code for $commandName" {
                        $Results = Invoke-WebRequest -Uri $link -UseBasicParsing
                        $Results.StatusCode | Should -Be '200'
                    }
                }
            }
        }
    }
}
