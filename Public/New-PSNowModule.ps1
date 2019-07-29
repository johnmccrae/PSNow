<#
.SYNOPSIS
A module used to create new PS Modules with.

.DESCRIPTION
This module uses Plaster to create all the essential parts of a PowerShell Module. It runs on PSCore and all supported platforms.

.EXAMPLE
New-PSNow -NewModuleName "MyFabModule" -BaseManifest Advanced

.EXAMPLE
New-PSNow -NewModuleName "MyFabModule" -BaseManifest Advanced -ModuleRoot ~/modules/myfabmodule

.EXAMPLE
New-PSNow -NewModuleName "MyFabModule" -BaseManifest Advanced -ModuleRoot c:\myfabmodule

.DEPENDENCIES
The following modules must be installed or this won't work at all
Plaster
Psake
PlatyPS
Pester
PSDepend


.NOTES

    # reference - https://kevinmarquette.github.io/2017-05-12-Powershell-Plaster-adventures-in/
    # reference - https://mikefrobbins.com/2018/02/15/using-plaster-to-create-a-powershell-script-module-template/
    # reference - Auf Deutsch! https://mycloudrevolution.com/2017/06/01/my-custom-plaster-template/
    # reference - https://kevinmarquette.github.io/2017-01-21-powershell-module-continious-delivery-pipeline/?utm_source=blog&utm_medium=blog&utm_content=titlelink
    # reference - https://github.com/PowerShell/platyPS
    # reference - https://overpoweredshell.com/Working-with-Plaster/#using-token-replacement
    # reference - https://github.com/ObjectivityLtd/PSCI

    General notes

#>


function New-PSNowModule {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$NewModuleName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Basic", "Extended", "Advanced")]
        [string]$BaseManifest,

        [Parameter(Mandatory = $false)]
        [string]$ModuleRoot = ""
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {

        $templateroot = $MyInvocation.MyCommand.Module.ModuleBase

        Set-Location $templateroot

        # check for old plastermanifest and delete it.
        if (Test-Path $templateroot\PlasterManifest.xml -PathType Leaf)
            {
                Remove-Item -Path PlasterManifest.xml
            }

        $plasterdoc = Get-ChildItem "$templateroot\PlasterTemplate" -Filter "$basemanifest.xml" | ForEach-Object { $_.FullName }

        Copy-Item -Path $plasterdoc "$templateroot\PlasterManifest.xml"

        if ($PSVersionTable.PSEdition -eq "Desktop") {

            if (!$moduleroot){
                $moduleroot = "c:\modules"
            }
            if (-not (Test-Path -path $moduleroot) ) {

                New-Item -Path "$moduleroot" -ItemType Directory
            }

            Set-Location $moduleroot
            $PathDivider = "\"

        }
        elseif ($PSVersionTable.PSEdition -eq "Core") {

            if (($isMACOS) -or ($isLinux)) {

                if (!$moduleroot) {
                    $moduleroot = "~/modules"
                }
                if (-not (Test-Path -path $moduleroot) ) {

                    New-Item -Path "$moduleroot" -ItemType Directory
                }

                Set-Location $ModuleRoot
                $PathDivider = "/"

            }
            else {

                if (!$moduleroot) {
                    $moduleroot = "c:\modules"
                }
                if (-not (Test-Path -path $moduleroot) ) {

                    New-Item -Path "$moduleroot" -ItemType Directory
                }

                Set-Location $moduleroot
                $PathDivider = "\"

            }
        }

        $PlasterParams = @{
            TemplatePath       = $templateroot #where the plaster manifest xml file lives
            Destination        = $moduleroot #where my new module is going to live
            ModuleName         = $NewModuleName
            #Description       = 'PowerShell Script Module Building Toolkit'
            #Version           = '1.0.0'
            ModuleAuthor       = '<Your Full Name Goes Here>'
            #CompanyName       = 'Chef Software Inc'
            #FunctionFolders   = 'public', 'private'
            #Git               = 'Yes'
            GitHubUserName	   = '<Your GitHub Name Goes Here>'
            #GitHubRepo        = 'ModuleBuildTools'
            #Options           = ('License', 'Readme', 'GitIgnore', 'GitAttributes')
            PowerShellVersion  = '3.0' #minimum PS version
            # Apart from Templatepath and Destination, these parameters need to match what's in the <parameters> section of the manifest.
        }

        Invoke-Plaster @PlasterParams -Force -Verbose

        $NewModuleName = $NewModuleName -replace '.ps1', ''

        #region File contents
        #keep this formatted as is. the format is output to the file as is, including indentation
        #$scriptCode = "function $NewModuleName {$([System.Environment]::NewLine)$([System.Environment]::NewLine)}"

        $scriptCode =
        @"
{
    function <%= $PLASTER_PARAM_ModuleName %> {
        [cmdletbinding()]
        param()
        begin{}
        process {}
        end {}
    }
}
"@

        $Path = "$moduleroot$PathDivider$NewModuleName"

        Write-Output "`nYour module was built at: $Path`n"

        if (Test-Path "$Path\public"){
            New-Item -Path "$Path\Public" -ItemType File -Name "$NewModuleName.ps1" -Value $scriptCode | Out-Null
        }
        else {
            New-Item -Path $Path -Name "$NewModuleName.ps1" -Content $scriptCode | Out-Null
        }

        if (-not (& Test-Path -Path $Path)) {
            New-Item -ItemType "file" -Path $templateroot -Name "currentmodules.txt" -Value $Path | Out-Null
        }
        else{
            add-content -path "$templateroot\currentmodules.txt" -value "$Path" | Out-Null
        }


    }
    end{}
}

