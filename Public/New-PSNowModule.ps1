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
        [ValidateNotNullOrWhiteSpace()]
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
        $originalLocation = Get-Location

        try {

        $templateroot = Split-Path $PSScriptRoot -Parent
        Set-Location $templateroot

        Set-Item -Path env:\BHPSVersionNumber -Value $((Get-Variable 'PSVersionTable' -ValueOnly).PSVersion.Major)

        $currentOs = GetPSNowOs
        $pathDivider = if ($currentOs -eq 'Windows') { '\' } else { '/' }
        Set-Item -Path env:\BHBuildOS      -Value $currentOs
        Set-Item -Path env:\BHPathDivider  -Value $pathDivider
        Set-Item -Path env:\BHTempDirectory -Value (Get-PSNowTempDirectory)
        Remove-OldPSNowManifest -TemplateRoot $templateroot -BaseManifest $BaseManifest

        if (!$ModuleRoot) {
            $ModuleRoot = if ($currentOs -eq 'Windows') { 'c:\modules' } else { '~/modules' }
        }
        if (-not (Test-Path -path $ModuleRoot)) {
            New-Item -Path "$ModuleRoot" -ItemType Directory
        }
        Set-Location $ModuleRoot

        $PlasterParams = @{
            TemplatePath       = $templateroot #where the plaster manifest xml file lives
            Destination        = $ModuleRoot #where my new module is going to live
            ModuleName         = $NewModuleName
            #Description       = 'PowerShell Script Module Building Toolkit'
            #Version           = '1.0.0'
            #CompanyName       = 'ACME Corp'
            #FunctionFolders   = 'public', 'private'
            #Git               = 'Yes'
            GitHubUserName	   = $env:BHGitHubUser
            #GitHubRepo        = 'ModuleBuildTools'
            #Options           = ('License', 'Readme', 'GitIgnore', 'GitAttributes')
            PowerShellVersion  = '5.0' #minimum PS version
            # Apart from Templatepath and Destination, these parameters need to match what's in the <parameters> section of the manifest.
        }

        $invokePlasterLogFields = [ordered]@{
            elapsed_ms  = 0
            module_name = $NewModuleName
            manifest    = $BaseManifest
            destination = $ModuleRoot
        }
        $invokePlasterStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        Write-PSNowStructuredLog -Operation 'invoke-plaster' -Status 'started' -Fields $invokePlasterLogFields

        try {
            Invoke-PSNowPlasterSafely -PlasterParams $PlasterParams

            $invokePlasterStopwatch.Stop()

            Write-PSNowStructuredLog -Operation 'invoke-plaster' -Status 'completed' -Fields ([ordered]@{
                elapsed_ms  = $invokePlasterStopwatch.ElapsedMilliseconds
                module_name = $NewModuleName
                manifest    = $BaseManifest
                destination = $ModuleRoot
            })
        }
        catch {
            $invokePlasterStopwatch.Stop()

            Write-PSNowStructuredLog -Operation 'invoke-plaster' -Status 'failed' -Fields ([ordered]@{
                elapsed_ms  = $invokePlasterStopwatch.ElapsedMilliseconds
                module_name = $NewModuleName
                manifest    = $BaseManifest
                destination = $ModuleRoot
                error       = $_.Exception.Message
            })

            throw
        }

        $NewModuleName = $NewModuleName -replace '\.ps1$', ''
        $Path = $($ModuleRoot + $env:BHPathDivider + $NewModuleName)
        Set-Location -Path $Path
        # Safe toggle: PSNOW_SAFE_MODE suppresses path output when set to a truthy value.
        $safeModeValue = [string]$env:PSNOW_SAFE_MODE
        $safeModeEnabled = $safeModeValue -match '^(1|true|yes|on)$'
        if (-not $safeModeEnabled) {
            Write-Output "`nYour module was built at: [$Path]`n"
        }

        $doc = Join-Path -Path $templateroot -ChildPath 'currentmodules.txt'
        Add-Content -Path $doc -Value $Path

        }
        finally {
            Set-Location -Path $originalLocation
        }
    }

}

