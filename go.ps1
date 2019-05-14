[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
[cmdletbinding()]
param(
    [Parameter(ValueFromPipeline, Mandatory = $true)]
    [ValidateSet('Major', 'Minor', 'Build', 'Revision')]
    [string]$BuildRev,
    [Parameter(Mandatory = $true)]
    [string]$Commit
)

$projectRoot = Resolve-Path "$PSScriptRoot"

$manifest = Import-PowerShellDataFile $projectRoot/New-MyPSModule.psd1
[version]$version = $Manifest.ModuleVersion
## Add none to the build of the version number
switch ( $BuildRev )
{
    Major { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f ($Version.Major +1), $Version.Minor, $Version.Build, $version.Revision  }
    Minor { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, ($Version.Minor +1), $Version.Build, $version.Revision   }
    Build { [version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, $Version.Minor, ($Version.Build +1), $version.Revision  }
    Revision {[version]$NewVersion = "{0}.{1}.{2}.{3}" -f $Version.Major, $Version.Minor, $Version.Build, ($version.Revision + 1) }
}
# Update the manifest file
Update-ModuleManifest -Path $projectRoot/New-MyPSModule.psd1 -ModuleVersion $NewVersion
# Sleep Incase of update
Start-Sleep -Seconds 15
# Find the Nuspec File
$MonolithFile = "$projectRoot/New-MyPSModule.nuspec"
#Import the New PSD file
$newString = Import-PowerShellDataFile $projectRoot/New-MyPSModule.psd1
#Create a new file and Update each time.
$xmlFile = New-Object xml
$xmlFile.Load($MonolithFile)
#Set the version to the one that is in the manifest.
$xmlFile.package.metadata.version = $newString.ModuleVersion
$xmlFile.Save($MonolithFile)

$date = Get-Date -Uformat "%D"
Add-Content -Path ./README.md -Value "**Version: $($newString.ModuleVersion)**"
Add-Content -Path ./README.md -Value "by *$($env:USERNAME) on $($date)*"

Write-Output "You chose this kind of a build revision: $BuildRev" 

git pull
git add -u
git commit -m $Commit
git push origin master

