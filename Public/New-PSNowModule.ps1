<#
.SYNOPSIS
A module used to create new PS Modules with.

.DESCRIPTION
This module uses Plaster to create all the essential parts of a PowerShell Module. It runs on PSCore and all supported platforms.

.PARAMETER NewModuleName
The name you wish to give your new module

.PARAMETER BaseManifest
You are selecting from 3 Plaster manifests located in the /PlasterTemplate directory - Advanced is the best choice

.PARAMETER ModuleRoot
Where do you want your new module to live? The default is to put it in a /Modules folder off your drive root

.EXAMPLE
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest basic

Creates the new PS Module using the "basic" plaster mainfest which creates a minimal module for you

.EXAMPLE
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest Extended -ModuleRoot ~/modules/myfabmodule

This choice uses the Extended manifest and create the module in /modules. Note that the module and pathing work for all versions of PS Core and PS Windows - Linux and OSX are supported platforms

.EXAMPLE
New-PSNowModule -NewModuleName "MyFabModule" -BaseManifest Advanced -ModuleRoot c:\myfabmodule

This choice creates a fully fleshed out PowerShell module with full support for Pester, Git, PlatyPS and more. See the Advanced.xml file located in /PlasterTemplate

.NOTES
General Notes
#>
function New-PSNowModule {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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

        $templateroot = Split-Path $PSScriptRoot -Parent
        Set-Location $templateroot

        function Remove-OldPSNowManifest{

            # check for old plastermanifest and delete it.
            if (Test-Path $($templateroot + $env:BHPathDivider + "PlasterManifest.xml") -PathType Leaf) {
                Remove-Item -Path PlasterManifest.xml
            }

            $plasterdoc = Get-ChildItem $($templateroot + $env:BHPathDivider + "PlasterTemplate") -Filter "$BaseManifest.xml" | ForEach-Object { $_.FullName }
            Copy-Item -Path $plasterdoc $($templateroot + $env:BHPathDivider + "PlasterManifest.xml")
        }

        Set-Item -Path env:\BHPSVersionNumber -Value $((Get-Variable 'PSVersionTable' -ValueOnly).PSVersion.Major)

        if ($env:BHPSVersionNumber -lt 6) {
            Set-Item -Path env:\BHBuildOS -Value 'Windows'
            Set-Item -Path env:\BHPathDivider -Value "\"
            Set-Item -Path env:\BHTempDirectory -Value $([System.IO.Path]::GetTempPath())
            Remove-OldPSNowManifest
            if (!$ModuleRoot) {
                $ModuleRoot = "c:\modules"
            }
            if (-not (Test-Path -path $ModuleRoot) ) {
                New-Item -Path "$ModuleRoot" -ItemType Directory
            }
            Set-Location $ModuleRoot
        }
        elseif (Get-Variable -Name 'IsWindows' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
            Set-Item -Path env:\BHBuildOS -Value 'Windows'
            Set-Item -Path env:\BHPathDivider -Value "\"
            Set-Item -Path env:\BHTempDirectory -Value $([System.IO.Path]::GetTempPath())
            Remove-OldPSNowManifest
            if (!$ModuleRoot) {
                $ModuleRoot = "c:\modules"
            }
            if (-not (Test-Path -path $ModuleRoot) ) {
                New-Item -Path "$ModuleRoot" -ItemType Directory
            }
            Set-Location $ModuleRoot
        }
        elseif (Get-Variable -Name 'IsMacOS' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
            Set-Item -Path env:\BHBuildOS -Value 'macOS'
            Set-Item -Path env:\BHPathDivider -Value "/"
            Set-Item -Path env:\BHTempDirectory -Value "/private/tmp"
            Remove-OldPSNowManifest
            if (!$ModuleRoot) {
                $ModuleRoot = "~/modules"
            }
            if (-not (Test-Path -path $ModuleRoot) ) {
                New-Item -Path "$ModuleRoot" -ItemType Directory
            }
            Set-Location $ModuleRoot
        }
        elseif (Get-Variable -Name 'IsLinux' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
            Set-Item -Path env:\BHBuildOS -Value 'Linux'
            Set-Item -Path env:\BHPathDivider -Value "/"
            Set-Item -Path env:\BHTempDirectory -Value "/tmp"
            Remove-OldPSNowManifest
            if (!$ModuleRoot) {
                $ModuleRoot = "~/modules"
            }
            if (-not (Test-Path -path $ModuleRoot) ) {
                New-Item -Path "$ModuleRoot" -ItemType Directory
            }
            Set-Location $ModuleRoot
        }

        $PlasterParams = @{
            TemplatePath       = $templateroot #where the plaster manifest xml file lives
            Destination        = $ModuleRoot #where my new module is going to live
            ModuleName         = $NewModuleName
            #Description       = 'PowerShell Script Module Building Toolkit'
            #Version           = '1.0.0'
            ModuleAuthor       = '<Your Full Name Goes Here>'
            #CompanyName       = 'ACME Corp'
            #FunctionFolders   = 'public', 'private'
            #Git               = 'Yes'
            GitHubUserName	   = $env:BHGitHubUser
            #GitHubRepo        = 'ModuleBuildTools'
            #Options           = ('License', 'Readme', 'GitIgnore', 'GitAttributes')
            PowerShellVersion  = '5.0' #minimum PS version
            # Apart from Templatepath and Destination, these parameters need to match what's in the <parameters> section of the manifest.
        }

        Invoke-Plaster @PlasterParams -Force -Verbose

        $NewModuleName = $NewModuleName -replace '.ps1', ''
        $Path = $($ModuleRoot + $env:BHPathDivider + $NewModuleName)
        Set-Location -Path $Path
        Write-Output "`nYour module was built at: [$Path]`n"

        $doc = $($templateroot + $env:BHPathDivider + "currentmodules.txt")
        if (-not (Test-Path -Path $doc)) {
            New-Item -ItemType "file" -Path $doc -Value $Path | Out-Null
        }
        else{
            Add-Content -path $doc -value "`r$Path" | Out-Null
        }
    }

}

