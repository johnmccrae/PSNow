# used by PSDepend to verify your dependencies are installed.

@{
    psake                              = 'latest'
    Pester                             = 'latest'
    BuildHelpers                       = 'latest'
    PSDeploy                           = 'latest'
    PlatyPS                            = 'latest'
    PSScriptAnalyzer                   = 'latest'
    # MyModuleName                     = '1.2.3' or 'latest'
    # repo 'ChefIT' = 'master'
}

<#
@{
    PSDeploy_0_1_21 = @{
        DependencyType = 'PSGalleryNuget'
        Name = 'PSDeploy'
        Version = '0.1.21'
        Target = "C:\ProjectX"
        Tags = 'prod'
        DependsOn = 'BuildHelpers'
        AddToPath = $True
        PostScripts = 'C:\SomeScripts.ps1'
    }

    # You can still mix in simple syntax
    BuildHelpers = '0.0.20'
}




#>
