<#

#>

# Build script parameters
param(
    [Parameter(ValueFromPipeline)]
    [ValidateSet('Major', 'Minor', 'Build', 'Revision')]
    [string]$BuildRev,
    [Parameter(ValueFromPipeline)]
    [switch]
    $WriteNewHelpFiles
)

# Ensure IB works in the strict mode.
Set-StrictMode -Version Latest

# Synopsis: We have a number of modules which must be installed, do that here.
task InstallDependencies {

    if (Get-Module -ListAvailable -Name Pester) {
        # Write-Host "Module exists"
        Update-Module -Name Pester
    } 
    else {
        Install-Module Pester -Force
    }

    if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
        # Write-Host "Module exists"
        Update-Module -Name PSScriptAnalyzer
    } 
    else {
        Install-Module PSScriptAnalyzer -Force
    }

    if (Get-Module -ListAvailable -Name Gherkin) {
        # Write-Host "Module exists"
        Update-Module -Name Gherkin
    } 
    else {
        Install-Module Gherkin -Force
    }

    if (Get-Module -ListAvailable -Name PlatyPS) {
        # Write-Host "Module exists"
        Update-Module -Name PlatyPS
    } 
    else {
        Install-Module PlatyPS -Force
    }
}


task UpdateHelp{
    $projectRoot = Resolve-Path "$PSScriptRoot"
    # $projectRoot = (Get-Location -PSProvider FileSystem).ProviderPath
    $moduleRoot = Split-Path (Resolve-Path "$projectRoot/<%= $PLASTER_PARAM_ModuleName %>.psm1")
    $moduleName = Split-Path $moduleRoot -Leaf

    Import-Module "$projectRoot/$moduleName.psm1"
    import-module platyPS

    if (-NOT($WriteNewHelpFiles)) {
        Update-MarkdownHelp .\docs
    }
    else {
        Remove-Item -path $moduleRoot\docs\*.* -Recurse -Force
        New-MarkdownHelp -Module $moduleRoot -OutputFolder .\docs
    }

    New-ExternalHelp .\docs -OutputPath en-US\ -force


}

# Synopsis: Remove temporary items.
task Clean {
    remove z, *\z, *\z.*, README.htm, Release-Notes.htm, <%= $PLASTER_PARAM_ModuleName %>.*.nupkg
}

# Synopsis: Get $script:Version from mymodule.psd1
task GetVersion {
    $manifest = Import-PowerShellDataFile <%= $PLASTER_PARAM_ModuleName %>.psd1
    [version]$script:Version = $manifest.ModuleVersion
    Write-Output $script:Version
    assert $script:Version
}

$Tests = 'SmokeTests.build.ps1', 'MoreTests.build.ps1'

task Test {
    foreach ($_ in $Tests) {
        Invoke-Build * $_
    }
}

# Synopsis: Set $script:Version from the mymodule.nuspec file.
task SetVersion {
    $manifest = Import-PowerShellDataFile <%= $PLASTER_PARAM_ModuleName %>.psd1
    [version]$Version = $manifest.ModuleVersion
    switch ( $BuildRev )
    {
        Major { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f ($Version.Major + 1), $Version.Minor, $Version.Build, $version.Revision  }
        Minor { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, ($Version.Minor + 1), $Version.Build, $version.Revision   }
        Build { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, $Version.Minor, ($Version.Build + 1), $version.Revision  }
        Revision {[version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, $Version.Minor, $Version.Build, ($version.Revision + 1) }
    }
    Update-ModuleManifest -Path <%= $PLASTER_PARAM_ModuleName %>.psd1 -ModuleVersion $NewVersion
}

# Synopsis: Make the module folder.
task Module {
    remove z
    $dir = "$BuildRoot"
    # make manifest
    Set-Content "$dir\<%= $PLASTER_PARAM_ModuleName %>.psd1" @"
@{
    ModuleVersion = '$script:Version'
    ModuleToProcess = '<%= $PLASTER_PARAM_ModuleName %>.psm1'
    GUID = 'a0319025-5f1f-47f0-ae8d-9c7e151a5aae'
    Author = '<%= $PLASTER_PARAM_ModuleAuthor %>'
    CompanyName = '<%= $PLASTER_PARAM_CompanyName %>'
    Copyright = '(c) <%= $PLASTER_PARAM_ModuleAuthor %>'
    Description = 'Build and test automation in PowerShell'
    PowerShellVersion = '4.0'
    PrivateData = @{
        PSData = @{
            Tags = 'Build', 'Test', 'Automation'
            ProjectUri = 'https://github.com/johnmccrae/<%= $PLASTER_PARAM_ModuleName %>'
            LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
            IconUri = 'https://raw.githubusercontent.com/johnmccrae/<%= $PLASTER_PARAM_ModuleName %>/maintenance.png'
        }
    }
}
"@
}

# Synopsis: Push with a version tag.
task PushRelease GetVersion, {
    $changes = exec { git status --short }
    assert (!$changes) "Please, commit changes."

    exec { git push }
    exec { git tag -a "v$script:Version" -m "v$script:Version" }
    exec { git push origin "v$script:Version" }
}

task . Pushrelease, GetVersion, Clean