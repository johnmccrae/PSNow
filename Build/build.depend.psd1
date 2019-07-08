@{
    # Defaults for all dependencies
    PSDependOptions  = @{
        Target     = 'CurrentUser'
        Parameters = @{
            # Use a local repository for offline support
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
    }

    # Dependency Management modules
    # PackageManagement = '1.2.2'
    # PowerShellGet     = '2.0.1'

    # Common modules
    BuildHelpers     = '2.0.7'
    Pester           = '4.6.0'
    PlatyPS          = '0.14.0'
    psake            = '4.8.0'
    PSDeploy         = '1.0.2'
    PSScriptAnalyzer = '1.18.1'
}
