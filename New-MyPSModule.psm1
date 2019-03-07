$Public = @( Get-ChildItem -Path $PSScriptRoot\New-MyPSModule.ps1 -ErrorAction SilentlyContinue )
#$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
#Foreach ($import in @($Public + $Private)) {
Foreach ($import in $Public) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

<# Add-Type -path "$PSSCriptRoot\Chef.PowerShell.GetChefPendingReboot.dll"

                  -OR-

$module = 'MyModule'
$manifestSplat = @{
    Path              = ".\$module\$module.psd1"
    Author            = 'Kevin Marquette'
    NestedModules     = @('bin\MyModule.dll')
    RootModule        = "$module.psm1"
    FunctionsToExport = @('Resolve-MyCmdlet')
}
New-ModuleManifest @manifestSplat
 #>

Export-ModuleMember -Function $Public.Basename
