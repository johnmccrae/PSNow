<#

    .SYNOPSIS
    Builds your PowerShell module. 

    .DESCRIPTION
    A tool to Build your module with. It can take several variables to flesh out your build environment and do
    your testing, build and publishing

    .PARAMETER Tasklist
    Tasks are:
    'Init' - sets the build location to the project root. Also adds /Staging and /Artifacts folders to .gitignore
    'Clean' - cleans up any files/folders from a previous build and creates the Aritact and Staging directories
    'CombineFunctionsAndStage' - pulls all your function files into a .psm1 and copies everything to /Staging
    'CreateModuleAndStage' - pulls all your files into /Staging in preparation for creation a .nupkg file
    'ImportStagingModule' - Import the module you just staged, you'll use that for making a .zip or .nupkg
    'Analyze' - Run PSScriptAnalyzer on the modules in /Staging to ensure linting and syntax are correct
    'Test' - Run Pester tests against the code. Tests are coming from /Tests
    'UpdateDocumentation' - Create/Update markdown helpfiles using PlatyPS
    'UpdateBuildVersion' - based on a parameter you pass (see below) the build number is updated
    'UpdateRepo' - does a git push back to your repo to sync your current files
    'CreateNuGetPackage' - builds a .nupkg file in the /Artifacts directory
    'CreateBuildArtifact' - creates a .zip file of your creation in the /Artifacts folder

    .PARAMETER PricingMatrix
    A hashtable pricing matrix for different tiers, with the keys being a concatenation of CPU count and
    Memory in GB.

    .PARAMETER ValidCPUMemoryMap
    A hashtable to validate acceptable CPU / Memory configurations.

    .INPUTS
    System.Object

    .OUTPUTS
    PSCustomObject

    .EXAMPLE
    Get-CIVM | Get-CIVMPrice

    Returns prices for all CIVMs.

    .EXAMPLE
    Get-CIVMPrice -CIVM $CIVM01, $CIVM02

    Returns prices for two CIVMs.

    .NOTES
    Author: Adam Rush
    
    .REFERENCES
    thanks to Adam Rush UK - https://adamrushuk.github.io/example-azure-devops-build-pipeline-for-powershell-modules/#test-1

#>
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
        Install-Module -Name 'PSDepend' -Scope 'CurrentUser' -Force
    }
    else {
        Write-Output "`nPSDepend already installed...skipping."
    }

    # Install build dependencies
    $psdependencyConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'build.depend.psd1'
    Write-Output "Checking / resolving module dependencies from [$psdependencyConfigPath]...`n"
    Import-Module -Name 'PSDepend'

    $invokePSDependParams = @{
        Path    = $psdependencyConfigPath
        # Tags = 'Bootstrap'
        Import  = $true
        Confirm = $false
        Install = $true
        # Verbose = $true
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
Set-Item -Path Env:BHBuildSystem -Value "Azure Pipelines"
$manifest = Import-PowerShellDataFile (Get-item env:\BHPSModuleManifest).Value
[version]$script:Version = $manifest.ModuleVersion
Set-Item -Path Env:BHBuildNumber -Value $script:Version
$stagingfolder = (Get-item env:\BHPSModulePath).Value + "/Staging"
Set-Item -Path env:\BHPSModulePath -Value $stagingfolder

# Capture the build version type - Major, Minor, Build, Revision. Used later to bump that version number
# The revision is passed in via the BuildRev parameter. 
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

# Execute PSake tasks
$invokePsakeParams = @{
    buildFile = (Join-Path -Path $env:BHProjectPath -ChildPath 'Build\build.psake.ps1')
    nologo    = $true
}
Invoke-Psake @invokePsakeParams @PSBoundParameters

Write-Output "`nFINISHED TASKS: $($TaskList -join ',')"
exit ( [int](-not $psake.build_success) )