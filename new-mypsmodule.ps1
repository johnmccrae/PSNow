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
        #$templateroot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('./')

        # check for old plastermanifest and delete it.
        if (Test-Path $templateroot\PlasterManifest.xml -PathType Leaf)
            {
                Remove-Item -Path PlasterManifest.xml
            }

        $plasterdoc = Get-ChildItem $templateroot -Filter $basemanifest -Recurse | % { $_.FullName }
        Copy-Item -Path $plasterdoc "$templateroot\PlasterManifest.xml"
        
        if ($PSVersionTable.PSEdition -eq "Desktop") {
            
            if (-not (Test-Path -path $moduleroot) ) {
            
                $moduleroot = "c:\modules"
                New-Item -Path "$moduleroot" -ItemType Directory
            }

            Set-Location $moduleroot 

        }
        elseif ($PSVersionTable.PSEdition -eq "Core") {

            if (($isMACOS) -or ($isLinux)) {

                if (-not (Test-Path -path $moduleroot) ) {
                    $moduleroot = "~/modules"
                    New-Item -Path "$moduleroot" -ItemType Directory
                }           
            
                Set-Location $moduleroot 

            }
            else {
                
                if (-not (Test-Path -path $moduleroot) ) {
                    $moduleroot = "c:\modules"
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
            #CompanyName       = 'mikefrobbins.com'
            #FunctionFolders   = 'public', 'private'
            #Git               = 'Yes'
            #GitRepoName       = 'ModuleBuildTools'
            #Options           = ('License', 'Readme', 'GitIgnore', 'GitAttributes')
            PowerShellVersion  = '3.0' #minimum PS version
            # Apart from Templatepath and Destination, these parameters need to match what's in the <parameters> section of the manifest. 
        }

        Invoke-Plaster @PlasterParams -Force -Verbose

    }
    # In the plaster manifest - any item that begins PLASTER_PARAM_somename is 'somename' from the <parameters> section
    end {}

}

#Export-ModuleMember -Function new-myposmodule