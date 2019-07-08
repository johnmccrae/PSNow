<#
    .SYNOPSIS
    Publishes the module to your preferred gallery

    .DESCRIPTION
    Long description

    .PARAMETER IncrementVersion
    Are you updating this as a Major, Minor or Build release

    .Parameter Gallery
    What PS Gallery will you be posting your module to?

    .Parameter NuGetAPIKey
    You'll need one from your Gallery to post things with

    .EXAMPLE
    Publish-MyPSModule -IncrementVersion Build -Gallery PSGallery -NuGetApiKEY SomeGuidGoeshere

    You call the module and pass in Major, Minor, Build or Revision, your Gallery, and finally your API Key


    .NOTES
    At the bottom of the script you'll need to explicitly modify the Publish command line where you need to provide credentials

#>

function Publish-MyPSModule {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Major", "Minor", "Build")]
        [string]$IncrementVersion,
        [Parameter(Mandatory = $true)]
        [ValidateSet("ChefITPS", "PSGallery")]
        [string]$Gallery,
        [Parameter(Mandatory = $true)]
        [ValidateSet("VSTS", "YourKeyGoesHere")]
        [string]$NuGetAPIKey
    )

    $moduleRoot = Resolve-Path "$PSScriptRoot\.."
    $moduleName = Split-Path $moduleRoot -Leaf


    function New-TemporaryDirectory {
        $parent = [System.IO.Path]::GetTempPath()
        [string] $name = [System.Guid]::NewGuid()
        $tempparent = New-Item -ItemType Directory -Path (Join-Path $parent $name)
        $fulldir = New-Item -ItemType Directory -Path (Join-Path $tempparent $moduleName)
        return $fulldir
    }


    $modulefolders = (
        "en-US",
        "Sample Docs",
        "PlasterTemplate",
        "Public",
        "Private",
        "Spec",
        "Tests"
    )

    $modulefiles = (
        "build.depend.ps1",
        "build.depend.psd1",
        "build.ps1",
        "commandFlow.ps1",
        "create-manifest.ps1",
        "default.build.ps1",
        "LICENSE",
        "License.yml",
        "mkdocs.yml",
        "New-MyPSModule.nuspec",
        "New-MyPSModule.psm1",
        "New-MyPSModule.psd1",
        "nuspec.txt",
        "psake.ps1",
        "PSScriptAnalyzerSettings.psd1",
        "readme.md",
        "readme.md.txt",
        "readme.ps1",
        "requirements.psd1",
        "template.psm1"
    )

    #region version
    # bump the version number

    # get the contents of the module manifest file
    try {
        $manifest = Import-PowerShellDataFile (Join-Path $moduleRoot "ChefITPS.psd1")
        [version]$version = $Manifest.ModuleVersion
    }
    catch {
        Write-Error "Failed to Get-Content"
    }


    $Major = $Version.Major
    $Minor = $Version.Minor
    $Build = $Version.Build
    $Revision = $Version.Revision

    # Add one to the build of the version number

    switch ( $IncrementVersion ) {
        Major {
            $Major = $Version.Major + 1
        }
        Minor {
            $Minor = $Version.Minor + 1
        }
        Build {
            $Build = $Version.Build + 1
        }
        Revision {
            $Revision = $Version.Revision + 1
        }
    }

    [version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Major, $Minor, $Build, $Revision

    try {
        Update-ModuleManifest (Join-Path $moduleRoot "ChefITPS.psd1") -ModuleVersion $NewVersion
        Write-Output "Updated Module Version from $Version to $NewVersion"
    }
    catch {
        Write-Error "Failed to Write New Version to disk"
    }



    # Add one to the build of the version number
    # $NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, $Version.Minor, $Version.Build, ($Version.Revision + 1)
    # Update the manifest file
    # Update-ModuleManifest -Path $(Build.SourcesDirectory)\ChefITPS.psd1 -ModuleVersion $NewVersion
    #endregion version


    $newtempdir = New-TemporaryDirectory
    Write-Output "Created the new directory at: " $newtempdir

    foreach ($folder in $modulefolders) {
        # New-Item -Path $newtempdir -Name $folder -ItemType Directory
        # Get-ChildItem -Path $sourceDir | Copy-Item -Destination $targetDir -Recurse -Container
        #Get-ChildItem -Path $folder | Copy-Item -Destination $newtempdir -Recurse
        Copy-Item $folder $newtempdir -Recurse -Container
    }

    foreach ($file in $modulefiles) {
        Copy-Item $file -Destination $newtempdir -Container
    }


    $patUser = (Get-ChildItem Env:\BHChefITAzureBuildUser).Value
    $patToken = (Get-ChildItem Env:\BHChefITAzureBuildPassword).Value
    $securePat = ConvertTo-SecureString -String $patToken -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($patUser, $securePat)


    publish-module -Path $newtempdir -Repository $Gallery -Credential $credential -NuGetApiKey $NuGetAPIKey -Verbose



}

