@{
    PSDependOptions  = @{
        Target    = '$DependencyPath/_build-cache/'
        AddToPath = $true
    }
    InvokeBuild      = '5.4.2'
    PSDeploy         = '1.0.1'
    PlatyPS          = '0.13.0'
    BuildHelpers     = '2.0.7'
    PSScriptAnalyzer = '1.17.1'
    Pester           = @{
        Version = '4.7.2'
    }
}
