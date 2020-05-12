<#
    .SYNOPSIS
    Builds your PowerShell module.

    .DESCRIPTION
    A tool to Build a basic module with. It can take several variables to flesh out your build environment and do
    your testing, build and publishing

    .PARAMETER Tasklist
    Tasks are:
    'Init' - sets the build location to the project root. Also adds /Staging and /BuildOutput folders to .gitignore
    'Clean' - cleans up any files/folders from a previous build and creates the Aritact and Staging directories
    'CombineAndStage' - pulls all your function files into a .psm1 and copies everything to /Staging
    'Stage' - pulls all your specified files into the /Staging folder in preparation for creation a .nupkg file or other artifact. Retains current directory structure.
    'ImportStagingModule' - Import the module you just staged, you'll use that for making a .zip or .nupkg. Separates your working tree from the code you are going to deploy
    'Analyze' - Run PSScriptAnalyzer on the modules in /Staging to ensure linting and syntax are correct
    'Test' - Run Pester tests against the code. Tests are coming from /Tests
    'Help' - Create/Update markdown helpfiles using PlatyPS
    'UpdateBuildVersion' - based on a parameter you pass (see below) the build number is updated
    'UpdateRepo' - does a git push back to your repo to sync your current files. Also tags files with the current build
    'BuildNuget' - builds a .nupkg file in the /BuildOutput directory
    'BuildZip' - creates a .zip file of your creation in the /BuildOutput folder
    'PublishAzure' - invokes Publish-Module to publish your code to your Azure Repo
    'PublishPSGallery' - invokes Publish-Module to publish to PowerShellGallery
    'Sign' - used to sign your module with a certificate

    .PARAMETER Parameters
    A hashtable of parameters you want to pass into your build. Ex.: @{BuildRev="REVISION", CommitMessage="I updated the build revision"}

    .PARAMETER Properties
    A hashtable to update various pathes and other settings used by this script

    .INPUTS
    System.Object

    .OUTPUTS
    PS Module

    .EXAMPLE
   ./Build/build.ps1 -Tasklist init -ResolveDependency

   Resolves your dependencies as specified in the build.depend.ps1 file and sets the build environment up for you.

    .EXAMPLE
    ./Build/build.ps1 -Tasklist BuildNuget -Parameters @{BuildRev="Revision"; CommitMessage="First Commit"}

    .NOTES
    Author: John McCrae

    .REFERENCES
    thanks to Adam Rush UK - https://adamrushuk.github.io/example-azure-devops-build-pipeline-for-powershell-modules/#test-1

#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[CmdletBinding()]
param (
    [Parameter()]
    [System.String[]]
    $TaskList = 'Default',

    [Parameter()]
    [System.Collections.Hashtable]
    $Parameters,

    [Parameter()]
    [System.Collections.Hashtable]
    $Properties,

    [Parameter()]
    [Switch]
    $ResolveDependency
)

Write-Output "`nSTARTED TASKS: $($TaskList -join ',')`n"

Write-Output "`nPowerShell Version Information:"
$PSVersionTable


# Load dependencies
if ($PSBoundParameters.Keys -contains 'ResolveDependency') {
    # Bootstrap environment
    Get-PackageProvider -Name 'NuGet' -ForceBootstrap | Out-Null

    # Install PSDepend module if it is not already installed
    if (-not (Get-Module -Name 'PSDepend' -ListAvailable)) {
        Write-Output "`nPSDepend is not yet installed...installing PSDepend now..."
        Install-Module -Name 'PSDepend' -Scope 'CurrentUser'  -Repository PSGALLERY -Force
    }
    else {
        Write-Output "`nPSDepend already installed...skipping."
    }

    #checking for the presence of Git. The Buildhelpers dependency will fail at the end of setup if Git isn't installed
    try {
        git | Out-Null
        #$gitinstalled = $true
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        $LASTEXITCODE = 1
        #$gitinstalled = $false
        throw "A git client was not detected. Please install one and re-run 'build.ps1  -ResolveDependency'"
    }

    # Install build dependencies
    $psdependencyConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'build.depend.psd1'
    Write-Output "Checking / resolving module dependencies from [$psdependencyConfigPath]...`n"
    Import-Module -Name 'PSDepend'

    $invokePSDependParams = @{
        Path    = $psdependencyConfigPath
        Tags    = 'Bootstrap'
        Import  = $true
        Confirm = $false
        Install = $true
        Verbose = $true
    }
    Invoke-PSDepend @invokePSDependParams

    # Remove ResolveDependency PSBoundParameter ready for passthru to PSake
    $PSBoundParameters.Remove('ResolveDependency')
}
else {
    Write-Host "Skipping dependency check...`n" -ForegroundColor 'Yellow'
}


# Init BuildHelpers
Set-BuildEnvironment -Force

## - jfm
Set-Item -Path env:\BHPSVersionNumber -Value $((Get-Variable 'PSVersionTable' -ValueOnly).PSVersion.Major)

$pathChar = [System.IO.Path]::DirectorySeparatorChar
Set-Item -Path env:\BHPathDivider -Value $pathChar

if ($env:BHPSVersionNumber -lt 6) {
    Set-Item -Path env:\BHBuildOS -Value 'Windows'
    Set-Item -Path env:\BHTempDirectory -Value $([System.IO.Path]::GetTempPath())
}
elseif (Get-Variable -Name 'IsWindows' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
    Set-Item -Path env:\BHBuildOS -Value 'Windows'
    Set-Item -Path env:\BHTempDirectory -Value $([System.IO.Path]::GetTempPath())
}
elseif (Get-Variable -Name 'IsMacOS' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
    Set-Item -Path env:\BHBuildOS -Value 'macOS'
    Set-Item -Path env:\BHTempDirectory -Value "/private/tmp"
}
elseif (Get-Variable -Name 'IsLinux' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
    Set-Item -Path env:\BHBuildOS -Value 'Linux'
    Set-Item -Path env:\BHTempDirectory -Value "/tmp"
}
## - jfm

# The Default Build Helpers variable settings leave some gaps that need resolving. Doing that here.
#region - BHBUILDVARS
Set-Item -Path Env:BHBuildCulture -Value (get-culture).name
Set-Item -Path Env:BHBuildSystem -Value "Azure Pipelines"

$manifest = Import-PowerShellDataFile (Get-item env:\BHPSModuleManifest).Value
[version]$script:Version = $manifest.ModuleVersion
Set-Item -Path Env:BHBuildNumber -Value $script:Version

$stagingfolder = (Get-item env:\BHPSModulePath).Value + $env:BHPathDivider + "Staging"
Set-Item -Path env:\BHPSModulePath -Value $stagingfolder

$publishfolder = $ENV:BHModulePath + $env:BHPathDivider + "Staging" + $env:BHPathDivider + $ENV:BHProjectName
Set-Item -Path env:\BHModulePath -Value $publishfolder
#endregion

# Capture the build version type - Major, Minor, Build, Revision. Used later to bump the version number of your package
# The revision is passed in via the BuildRev parameter.
# also grabbing a Commit message so we an do a git push to your Repo.
if ($PSBoundParameters.Keys -contains 'Parameters') {
    foreach ($key in $Parameters.Keys) {
        if ($key -eq 'BuildRev') {
            $versiondetail = $Parameters.$key
            Set-Item -Path Env:BHBuildRevision -Value $versiondetail
        }
        elseif ($key -eq 'CommitMessage') {
            $commitMessage = $Parameters.$key
            Set-Item -Path Env:BHCommitMessage -Value $commitMessage
            Set-Item -Path Env:BHCommitFlag -Value 1
        }
    }
}

# If you don't specify a build version change, we go with no change
if ($PSBoundParameters.ContainsKey('Tasklist')) {
    if ((($TaskList -like "*Build*") -or ($TaskList -like "*Publish*")) -and ($Parameters.Keys -notcontains "BuildRev")) {
        $PSBoundParameters.Parameters += @{BuildRev = 'None' }
    }
    elseif (($TaskList -like "*Publish*") -and ((Get-Item -Path env:\BH*).Name -notcontains "BHPSGalleryKey")) {
        Write-Host "You need to create the environmental variable 'BHPSGalleryKey' with your PowerShell Gallery key" -ForegroundColor 'Red' -BackgroundColor 'Black'
        Break
    }

    # Execute PSake tasks
    $invokePsakeParams = @{
        buildFile = (Join-Path -Path $env:BHProjectPath -ChildPath $("Build" + $env:BHPathDivider + "build.psake.ps1"))
        nologo    = $true
    }
    Invoke-Psake @invokePsakeParams @PSBoundParameters

}

Write-Output "`nFINISHED TASKS: $($TaskList -join ',')"
exit ( [int](-not $psake.build_success) )