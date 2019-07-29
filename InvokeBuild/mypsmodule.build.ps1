<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
.Description
	TASKS AND REQUIREMENTS
	Run tests and compare results with expected
		- Assert-SameFile.ps1 https://www.powershellgallery.com/packages/Assert-SameFile
		- Invoke-PowerShell.ps1 https://www.powershellgallery.com/packages/Invoke-PowerShell
	Make help in PowerShell XML format
		- Helps.ps1 https://www.nuget.org/packages/Helps
	Convert markdown files to HTML
		- pandoc https://github.com/jgm/pandoc/releases
	Push to GitHub with a tag
		- git
	Make and push the NuGet package
		- NuGet
	Clean the project directory
#>

# Build script parameters
param(
    [switch]$NoTestDiff
)

# Ensure IB works in the strict mode.
Set-StrictMode -Version Latest

# Synopsis: Remove temporary items.
task Clean {
    remove z, *\z, *\z.*, README.htm, Release-Notes.htm, Invoke-Build.*.nupkg
}

# Synopsis: Set $script:Version from Release-Notes.
task Version {
    $manifest = Import-PowerShellDataFile ..\new-PSNow.psd1
    [version]$script:Version = $manifest.ModuleVersion
    assert $script:Version
}

# Synopsis: Make the module folder.
task Module {
    remove z
    $dir = "$BuildRoot"
    # make manifest
    Set-Content "$dir\InvokeBuild.psd1" @"
@{
    ModuleVersion = '$script:Version'
    ModuleToProcess = 'MyBuild.psm1'
    GUID = 'a0319025-5f1f-47f0-ae8d-9c7e151a5aae'
    Author = 'Roman Kuzmin'
    CompanyName = 'Roman Kuzmin'
    Copyright = '(c) Roman Kuzmin'
    Description = 'Build and test automation in PowerShell'
    PowerShellVersion = '2.0'
    AliasesToExport = 'Invoke-Build', 'Build-Checkpoint', 'Build-Parallel'
    PrivateData = @{
        PSData = @{
            Tags = 'Build', 'Test', 'Automation'
            ProjectUri = 'https://github.com/nightroman/Invoke-Build'
            LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
            IconUri = 'https://raw.githubusercontent.com/nightroman/Invoke-Build/master/ib.png'
            ReleaseNotes = 'https://github.com/nightroman/Invoke-Build/blob/master/Release-Notes.md'
        }
    }
}
"@
}

# Synopsis: Push with a version tag.
task PushRelease Version, {
    $changes = exec { git status --short }
    assert (!$changes) "Please, commit changes."

    exec { git push }
    exec { git tag -a "v$script:Version" -m "v$script:Version" }
    exec { git push origin "v$script:Version" }
}

task . Pushrelease, Version, Clean