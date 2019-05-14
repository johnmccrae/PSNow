@{
    PSDependOptions = @{
        Target    = '$DependencyPath/_build-cache/'
        AddToPath = $true
    }
    psdeploy     = @{
        version = '1.0.1'
        target  = 'C:\ProjectX'
        source  = 'PSGalleryModule'
    }
    buildhelpers = @{
        target = 'CurrentUser'
    }
    pester       = 'latest'
    psake        = 'latest'
}
