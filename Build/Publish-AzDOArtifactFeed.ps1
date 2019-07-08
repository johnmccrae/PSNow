[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
[CmdletBinding()]
param (
    [string]$AzDOAccountName = 'adamrushuk',
    [string]$AzDOArtifactFeedName = 'dev',
    [string]$AzDOPat,
    [string]$ModuleFolderPath = (Join-Path -Path $env:SYSTEM_ARTIFACTSDIRECTORY -ChildPath "PowerShellPipeline\PSModule\PSvCloud")
)

# Variables
$feedUsername = 'NotChecked'
$packageSourceUrl = "https://$($AzDOAccountName).pkgs.visualstudio.com/_packaging/$AzDOArtifactFeedName/nuget/v2" # NOTE: v2 Feed

# Troubleshooting
# Write-Host "PAT param passed in: [$AzDOPat]"
# Get-ChildItem env: | Format-Table -AutoSize


# This is downloaded during Step 3, but could also be "C:\Users\USERNAME\AppData\Local\Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe"
# if not running script as Administrator.
$nugetPath = (Get-Command NuGet.exe).Source
if (-not (Test-Path -Path $nugetPath)) {
    # $nugetPath = 'C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe'
    $nugetPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe'
}

# Create credential
$password = ConvertTo-SecureString -String $AzDOPat -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($feedUsername, $password)


# Step 1 - "Install NuGet" Agent job task now handles this
# Upgrade PowerShellGet
# Install-Module PowerShellGet -RequiredVersion $powershellGetVersion -Force
# Remove-Module PowerShellGet -Force
# Import-Module PowerShellGet -RequiredVersion $powershellGetVersion -Force


# Step 2
# Check NuGet is listed
Get-PackageProvider -Name 'NuGet' -ForceBootstrap | Format-List *


# Step 3
# THIS WILL FAIL first time, so don't panic!
# Try to Publish a PowerShell module - this will prompt and download NuGet.exe, and fail publishing the module (we publish at the end)
$publishParams = @{
    Path        = $ModuleFolderPath
    Repository  = $AzDOArtifactFeedName
    NugetApiKey = 'VSTS'
    Force       = $true
    Verbose     = $true
    ErrorAction = 'SilentlyContinue'
}
Publish-Module @publishParams


# Step 4
# Register NuGet Package Source
& $nugetPath Sources Add -Name $AzDOArtifactFeedName -Source $packageSourceUrl -Username $feedUsername -Password $AzDOPat

# Check new NuGet Source is registered
& $nugetPath Sources List


# Step 5
# Register feed
$registerParams = @{
    Name                      = $AzDOArtifactFeedName
    SourceLocation            = $packageSourceUrl
    PublishLocation           = $packageSourceUrl
    InstallationPolicy        = 'Trusted'
    PackageManagementProvider = 'Nuget'
    Credential                = $credential
    Verbose                   = $true
}
Register-PSRepository @registerParams

# Check new PowerShell Repository is registered
Get-PSRepository -Name $AzDOArtifactFeedName


# Step 6
# Publish PowerShell module (2nd time lucky!)
Publish-Module @publishParams