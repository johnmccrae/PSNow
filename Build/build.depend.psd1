# Build dependencies - consumed by build.ps1 via Microsoft.PowerShell.PSResourceGet
# Format: 'ModuleName' = 'MinimumVersion'
# psake and Plaster are pinned to tested versions; bump only after validation.
@{
    BuildHelpers                   = '2.0.16'
    Plaster                        = '1.1.3'
    Pester                         = '5.7.1'
    'Microsoft.PowerShell.PlatyPS' = '1.0.1'
    PSake                          = '4.9.0'
    PSDeploy                       = '1.0.5'
    PSScriptAnalyzer               = '1.25.0'
    'posh-git'                     = '1.1.0'
}
