$manifest = Import-PowerShellDataFile New-PSNow.psd1
[version]$version = $Manifest.ModuleVersion
# Add one to the build of the version number
[version]$NewVersion = "{0}.{1}.{2}" -f $Version.Major, $Version.Minor, ($Version.Build + 1)
# Update the manifest file
Update-ModuleManifest -Path .\BeardAnalysis.psd1 -ModuleVersion $NewVersion




Import-Module .\New-PSNow.psm1

Get-Command -Module New-PSNow |
    Sort-Object Noun, Verb |
    New-PSNow `
    -Title 'Get-HelpAsMarkDown' `
    -Description 'PowerShell module for converting PowerShell help information to MarkDown' `
    -PrefacePath ./PREFACE.md |
    Out-File .\README.md -Encoding utf8



Import-Module UncommonSense.PowerShell.Documentation -Force

Get-Command -Module New-PSNow |
    Sort-Object Noun, Verb |
    Convert-HelpToMarkDown `
    -Title 'New-PSNow' `
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


<?xml version="1.0" encoding="utf-8"?>
<configuration>
<packageSources>
<add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
<add key="MyPrivateFeed" value="https://pkgs.dev.azure.com/chefcorp-chefIT/_packaging/chefitps/nuget/v3/index.json" />
</packageSources>
<packageSourceCredentials>
<MyPrivateFeed>
<add key="Username" value="itautomation@chef.io" />
<add key="ClearTextPassword" value="kozxlixxi3mc4jzm4sg4ljbmmtjj53h3cvbvaqy34fsbtmz7bv3q" />
</MyPrivateFeed>
</packageSourceCredentials>
</configuration>


$patUser = $chef[0].AccountEmail
$patToken = $chef[5].AccountPassword
$securePat = ConvertTo-SecureString -String $patToken -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($patUser, $securePat)

Register-PSRepository -Name 'ChefITPS' -SourceLocation 'https://pkgs.dev.azure.com/chefcorp-chefIT/_packaging/chefitps/nuget/v2/' -PublishLocation 'https://pkgs.dev.azure.com/chefcorp-chefIT/_packaging/chefitps/_packaging/chefitps/nuget/v2/' -InstallationPolicy Trusted -Credential $credential -Verbose





PS D:\> $MyCertFromPfx = Get-PfxCertificate -FilePath D:\MyNewSigningCertificate.pfx
Enter password: **********************
PS D:\> Set-AuthenticodeSignature -PSPath .\ToBeSigned.ps1 -Certificate $MyCertFromPfx



