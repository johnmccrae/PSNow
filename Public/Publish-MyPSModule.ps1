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

.NOTES
At the bottom of the script you'll need to explicitly modify the Publish command line where you need to provide credentials
#>

function Publish-MyPSModule {
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
        [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
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
        $file = (Get-Content "$moduleName.psd1")
    }
    catch {
        Write-Error "Failed to Get-Content"
    }

    # Use RegEx to get the Version Number and set it as a version datatype
    # \s* - between 0 and many whitespace
    # ModuleVersion - literal
    # \s - 1 whitespace
    # = - literal
    # \s - 1 whitespace
    # ' - literal
    # () - capture Group
    # \d* - between 0 and many digits
    # ' - literal
    # \s* between 0 and many whitespace

    [version]$Version = [regex]::matches($file, "\s*ModuleVersion\s=\s'(\d*.\d*.\d*)'\s*").groups[1].value

    $Major = $Version.Major
    $Minor = $Version.Minor
    $Build = $Version.Build

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
    }

    [version]$NewVersion = "{0}.{1}.{2}" -f $Major, $Minor, $Build

    try {
        (Get-Content "$moduleName.psd1") -replace $version, $NewVersion | Out-File "$moduleName.psd1"
        Write-Output "Updated Module Version from $Version to $NewVersion"
    }
    catch {
        Write-Error "Failed to Write New Version to disk"
    }


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


    $patUser = 'itautomation@chef.io'
    $patToken = 'kozxlixxi3mc4jzm4sg4ljbmmtjj53h3cvbvaqy34fsbtmz7bv3q'
    $securePat = ConvertTo-SecureString -String $patToken -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($patUser, $securePat)


    publish-module -Path $newtempdir -Repository $Gallery -Credential $credential -NuGetApiKey $NuGetAPIKey -Verbose



}

