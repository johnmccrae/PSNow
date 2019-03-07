<#
.SYNOPSIS
A module used to create new PS Modules with. 

.DESCRIPTION
This module uses Plaster to create all the essential parts of a PowerShell Module

.EXAMPLE
New-MyPSModule -MyNewModuleName "MyFabModule" -

.DEPENDENCIES
The following modules must be installed or this won't work at all
Plaster
InvokeBuild
PSGraph
PlatyPS
Pester

.NOTES

    # reference - https://kevinmarquette.github.io/2017-05-12-Powershell-Plaster-adventures-in/
    # reference - https://mikefrobbins.com/2018/02/15/using-plaster-to-create-a-powershell-script-module-template/
    # reference - Auf Deutsch! https://mycloudrevolution.com/2017/06/01/my-custom-plaster-template/
    # reference - https://kevinmarquette.github.io/2017-01-21-powershell-module-continious-delivery-pipeline/?utm_source=blog&utm_medium=blog&utm_content=titlelink
    # reference - https://github.com/PowerShell/platyPS
    # reference - https://overpoweredshell.com/Working-with-Plaster/#using-token-replacement

    General notes




#>

function New-MyPSModule {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MyNewModuleName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("PlasterManifest-basic.xml", "PlasterManifest-extended.xml", "PlasterManifest-extended2.xml")]
        [string]$BaseManifest,

        [Parameter(Mandatory = $false)]
        [string]$modulepath = ""
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {

        $templateroot = $PSScriptRoot
        
        Set-Location $PSScriptRoot

        #$templateroot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('./')

        # check for old plastermanifest and delete it.
        if (Test-Path $templateroot\PlasterManifest.xml -PathType Leaf)
            {
                Remove-Item -Path PlasterManifest.xml
            }

        $plasterdoc = Get-ChildItem $templateroot -Filter $basemanifest -Recurse | % { $_.FullName }
        Copy-Item -Path $plasterdoc "$templateroot\PlasterManifest.xml"
        
        if ($PSVersionTable.PSEdition -eq "Desktop") {
            
            if (!$moduleroot){
                $moduleroot = "c:\modules"
            }
            if (-not (Test-Path -path $moduleroot) ) {
            
                New-Item -Path "$moduleroot" -ItemType Directory
            }

            Set-Location $moduleroot 

        }
        elseif ($PSVersionTable.PSEdition -eq "Core") {

            if (($isMACOS) -or ($isLinux)) {

                if (!$moduleroot) {
                    $moduleroot = "~/modules"
                }
                if (-not (Test-Path -path $moduleroot) ) {

                    New-Item -Path "$moduleroot" -ItemType Directory
                }           
            
                Set-Location $moduleroot 

            }
            else {
                
                if (!$moduleroot) {
                    $moduleroot = "c:\modules"
                }
                if (-not (Test-Path -path $moduleroot) ) {
            
                    New-Item -Path "$moduleroot" -ItemType Directory
                }

                Set-Location $moduleroot 
                
            }
        }

        $PlasterParams = @{
            TemplatePath       = $templateroot #where the plaster manifest xml file lives
            Destination        = $moduleroot
            ModuleName         = $MyNewModuleName
            #Description       = 'PowerShell Script Module Building Toolkit'
            #Version           = '1.0.0'
            ModuleAuthor       = 'John McCrae'
            #CompanyName       = 'Chef Software Inc'
            #FunctionFolders   = 'public', 'private'
            #Git               = 'Yes'
            GitHubUserName	   = 'johnmccrae'
            #GitHubRepo        = 'ModuleBuildTools'
            #Options           = ('License', 'Readme', 'GitIgnore', 'GitAttributes')
            PowerShellVersion  = '3.0' #minimum PS version
            # Apart from Templatepath and Destination, these parameters need to match what's in the <parameters> section of the manifest. 
        }

        Invoke-Plaster @PlasterParams -Force -Verbose

            $Name = $Name -replace '.ps1', ''

        #region File contents
        #keep this formatted as is. the format is output to the file as is, including indentation
        $scriptCode = "function $Name {$([System.Environment]::NewLine)$([System.Environment]::NewLine)}"

        $testCode = '$here = Split-Path -Parent $MyInvocation.MyCommand.Path
        $sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace ''\.Tests\.'', ''.''
        . "$here\$sut"

        Describe "#name#" {
            It "does something useful" {
                $true | Should -Be $false
            }
        }' -replace "#name#", $Name

        #endregion

        $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($moduleroot)

        if(Test-Path "$moduleroot\public"){
            Create-File -Path "$Path\Public" -Name "$Name.ps1" -Content $scriptCode
        }
        else {
            Create-File -Path $Path -Name "$Name.ps1" -Content $scriptCode
        }

        if(Test-Path "$moduleroot\tests"){
            Create-File -Path "$Path\tests" -Name "$Name.Tests.ps1" -Content $testCode
        }
        else{
            Create-File -Path $Path -Name "$Name.Tests.ps1" -Content $testCode
        }
        function Create-File ($Path, $Name, $Content) {
            if (-not (& $SafeCommands['Test-Path'] -Path $Path)) {
                & $SafeCommands['New-Item'] -ItemType Directory -Path $Path | & $SafeCommands['Out-Null']
            }

            $FullPath = & $SafeCommands['Join-Path'] -Path $Path -ChildPath $Name
            if (-not (& $SafeCommands['Test-Path'] -Path $FullPath)) {
                & $SafeCommands['Set-Content'] -Path  $FullPath -Value $Content -Encoding UTF8
                & $SafeCommands['Get-Item'] -Path $FullPath
            }
            else {
                # This is deliberately not sent through $SafeCommands, because our own tests rely on
                # mocking Write-Warning, and it's not really the end of the world if this call happens to
                # be screwed up in an edge case.
                Write-Warning "Skipping the file '$FullPath', because it already exists."
            }

            # In the plaster manifest - any item that begins PLASTER_PARAM_somename is 'somename' from the <parameters> section
            end {}

        }

    }

#Export-ModuleMember -Function new-myposmodule