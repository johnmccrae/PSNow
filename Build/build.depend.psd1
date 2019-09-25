@{
    # Defaults for all dependencies
    PSDependOptions = @{
        Target     = 'CurrentUser'
        Parameters = @{
            # Use a local repository for offline support
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
    }

    # https://github.com/RamblingCookieMonster/PSDepend -half way down the page describes this file
    # Dependency Management modules
    # PackageManagement = '1.2.2'
    # PowerShellGet     = '2.0.1'

    # Common modules
    Buildhelpers_2_0_11 = @{
        Name           = 'buildhelpers'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
        Version        = '2.0.11'
        Tags           = 'prod', 'test', 'bootstrap'
        #PreScripts     = 'C:\RunThisFirst.ps1'
        #DependsOn      = 'some_task'
    }

    Pester_4_9_0 = @{
        Name           = 'pester'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
        Version        = '4.9.0'
        Tags           = 'bootstrap'
    }

    PlatyPS_0_14_0 = @{
        Name           = 'platyps'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
        Version        = '0.14.0'
        Tags           = 'bootstrap'
    }

    Psake_4_9_0 = @{
        Name           = 'psake'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
        Version        = '4.9.0'
        Tags           = 'bootstrap'
    }

    PSDeploy_1_0_3 = @{
        Name           = 'psdeploy'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
        Version        = '1.0.3'
        Tags           = 'build', 'test', 'deploy', 'bootstrap'
    }


    PSScriptAnalyzer_1_18_3 = @{
        Name           = 'psscriptanalyzer'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
        Version        = '1.18.3'
        Tags           = 'test', 'bootstrap'
    }

    "POSH-GIT_0_7_3"        = @{
        Name           = 'posh-git'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository         = 'PSGallery'
            SkipPublisherCheck = $true
        }
        Version        = '0.7.3'
        Tags           = 'publish', 'bootstrap'
    }
}
