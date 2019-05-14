<#
.Description
Installs and loads all the required modules for the build.
Derived from scripts written by Warren F. (RamblingCookieMonster)

https://github.com/RamblingCookieMonster/BuildHelpers/blob/master/BuildHelpers/Public/Step-ModuleVersion.ps1


#>
Function Submit-MyPSModule {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Task
    )

    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    # $moduleRoot = Split-Path (Resolve-Path "$projectRoot\*.psm1")
    # $moduleName = Split-Path $projectRoot -Leaf

    Write-Output "Starting build"

    if (-not (Get-PackageProvider | Where-Object Name -eq nuget))
    {
        Write-Output "  Install Nuget PS package provider"
        Install-PackageProvider -Name NuGet -Force -Confirm:$false | Out-Null
    }

    $publishRepository = '<My Repository Goes Here>'

    # Grab nuget bits, install modules, set build variables, start build.
    Write-Output "  Install And Import Build Modules"
    $psDependVersion = '0.3.0'
    if (-not(Get-InstalledModule PSDepend -RequiredVersion $psDependVersion -EA SilentlyContinue))
    {
        Install-Module PSDepend -RequiredVersion $psDependVersion -Force -Scope CurrentUser
    }
    Import-Module PSDepend -RequiredVersion $psDependVersion
    Invoke-PSDepend -Path "$projectRoot\Scaffold\build.depend.psd1" -Install -Import -Force

    if (-not (Get-Item env:\BH*))
    {
        Set-BuildEnvironment
        Set-Item env:\PublishRepository -Value $publishRepository
    }
    . "$projectRoot\tests\Remove-SUT.ps1"

    Write-Output "  InvokeBuild"
    set-location $projectRoot
    Invoke-Build $Task -File "$projectRoot\Scaffold\default.build.ps1" -Result result
    if ($Result.Error)
    {
        exit 1
    }
    else
    {
        exit 0
    }

    <#

    param ($Task = 'Default')

    # Grab nuget bits, install modules, set build variables, start build.
    Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

    Install-Module Psake, PSDeploy, BuildHelpers -force -AllowClobber -Scope CurrentUser
    Install-Module Pester -MinimumVersion 4.1 -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser
    Import-Module Psake, BuildHelpers

    Set-BuildEnvironment -ErrorAction SilentlyContinue

    Invoke-psake -buildFile $ENV:BHProjectPath\psake.ps1 -taskList $Task -nologo
    exit ( [int]( -not $psake.build_success ) )




    #>
}
