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

task UpdateHelp{
    $projectRoot = Resolve-Path "$PSScriptRoot"
    # $projectRoot = (Get-Location -PSProvider FileSystem).ProviderPath
    $moduleRoot = Split-Path (Resolve-Path "$projectRoot/PSNow.psm1")
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
    remove z, *\z, *\z.*, README.htm, Release-Notes.htm, PSNow.*.nupkg
}

# Synopsis: Get $script:Version from mymodule.psd1
task GetVersion {
    $manifest = Import-PowerShellDataFile PSNow.psd1
    [version]$script:Version = $manifest.ModuleVersion
    Write-Output $script:Version
    assert $script:Version
}

$Tests = 'Analyzer.build.ps1', 'MoreTests.build.ps1'

task Test {
    foreach ($_ in $Tests) {
        Invoke-Build * $_
    }
}

# Synopsis: Set $script:Version from the mymodule.nuspec file.
task SetVersion {
    $manifest = Import-PowerShellDataFile PSNow.psd1
    [version]$Version = $manifest.ModuleVersion
    switch ( $BuildRev )
    {
        Major { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f ($Version.Major + 1), $Version.Minor, $Version.Build, $version.Revision  }
        Minor { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, ($Version.Minor + 1), $Version.Build, $version.Revision   }
        Build { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, $Version.Minor, ($Version.Build + 1), $version.Revision  }
        Revision {[version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, $Version.Minor, $Version.Build, ($version.Revision + 1) }
    }
    Update-ModuleManifest -Path PSNow.psd1 -ModuleVersion $NewVersion

    exec { git commit PSNow.ps1 -m "Updating the module version"}
}

# Synopsis: Make the module folder.
task Module {
    remove z
    $dir = "$BuildRoot"
    # make manifest
    Set-Content "$dir\PSNow.psd1" @"
@{
    ModuleVersion = '$script:Version'
    ModuleToProcess = 'PSNow.psm1'
    GUID = 'a0319025-5f1f-47f0-ae8d-9c7e151a5aae'
    Author = 'John McCare'
    CompanyName = 'John McCare'
    Copyright = '(c) John McCrae'
    Description = 'Build and test automation in PowerShell'
    PowerShellVersion = '4.0'
    PrivateData = @{
        PSData = @{
            Tags = 'Build', 'Test', 'Automation'
            ProjectUri = 'https://github.com/johnmccrae/PSNow'
            LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
            IconUri = 'https://raw.githubusercontent.com/johnmccrae/PSNow/maintenance.png'
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