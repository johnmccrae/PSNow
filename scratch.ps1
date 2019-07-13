$manifest = Import-PowerShellDataFile New-MyPSModule.psd1
[version]$version = $Manifest.ModuleVersion
# Add one to the build of the version number
[version]$NewVersion = "{0}.{1}.{2}" -f $Version.Major, $Version.Minor, ($Version.Build + 1)
# Update the manifest file
Update-ModuleManifest -Path .\BeardAnalysis.psd1 -ModuleVersion $NewVersion




Import-Module .\New-MyPSModule.psm1

Get-Command -Module New-MyPSModule |
    Sort-Object Noun, Verb |
    New-MyPSModule `
    -Title 'Get-HelpAsMarkDown' `
    -Description 'PowerShell module for converting PowerShell help information to MarkDown' `
    -PrefacePath ./PREFACE.md |
    Out-File .\README.md -Encoding utf8



Import-Module UncommonSense.PowerShell.Documentation -Force

Get-Command -Module New-MyPSModule |
    Sort-Object Noun, Verb |
    Convert-HelpToMarkDown `
    -Title 'New-MyPSModule' `
    -Description 'PowerShell module for creating PowerShell Modules' `
    -PrefacePath .\PREFACE.md |
    Out-File .\README.md -Encoding utf8

trap {
"in Trap"
((get-date).ToString() + " ------- Error Information: -------") |
 Out-File -FilePath "c:\cmds\error.log" -Append

((get-date).ToString() + " - Script Name: " + $error[0].invocationinfo.ScriptName) |
 Out-File -FilePath "c:\cmds\error.log" -Append

((get-date).ToString() + " - Error occurred at line: " + $error[0].invocationinfo.ScriptLineNumber + "  at offset: " + $error[0].invocationinfo.OffSetInLine ) |
 Out-File -FilePath "c:\cmds\error.log" -Append

((get-date).ToString() + " - Line of code: " + $error[0].invocationinfo.Line) |
 Out-File -FilePath "c:\cmds\error.log" -Append

((get-date).ToString() + " - Error that was trapped: " + $error[0]) |
 Out-File -FilePath "c:\cmds\error.log" -Append

# 'n gives you a forced new line, for example 'n(what you want to print)
((get-date).ToString() + " - Script Error Message Line Indicator:" + $error[0].invocationinfo.positionmessage) |
 Out-File -FilePath "c:\cmds\error.log" -Append

 

 "stop here"   
}

$error.clear()
"Start Test"
 ((get-date).ToString() + " - Initiating Script ") |
 Out-File -FilePath "c:\cmds\error.log"

 $x = 1/$null
 "After bad statement 1"  
 
 "End of script"

$pat = 'kozxlixxi3mc4jzm4sg4ljbmmtjj53h3cvbvaqy34fsbtmz7bv3q'
$username = 'itautomation@chef.io'
$nuget_repo_name = 'ChefITPS'
$nuget_repo_feed = 'https://pkgs.dev.azure.com/chefcorp-chefIT/_packaging/chefitps/nuget/v2/'

$password = ConvertTo-SecureString $pat -AsPlainText -Force
$credsVSTS = New-Object System.Management.Automation.PSCredential $username, $password

Register-PSRepository -Name $nuget_repo_name -SourceLocation $nuget_repo_feed -PublishLocation $nuget_repo_feed -InstallationPolicy Trusted
