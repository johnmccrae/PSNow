# This code was taken verbatim from a Pester sample
function GetPSNowPsVersion {
    # accessing the value indirectly so it can be mocked
    (Get-Variable 'PSVersionTable' -ValueOnly).PSVersion.Major
}

function GetPSNowOs {
    # Prior to v6, PowerShell was solely on Windows. In v6, the $IsWindows variable was introduced.
    # Cache once so branch logic reads clearly and avoids repeated helper calls.
    $psVersionMajor = GetPSNowPsVersion

    if ($psVersionMajor -lt 6) {
        'Windows'
    }
    # Order matters: Windows, then macOS, then Linux to match existing behavior and tests.
    elseif (Get-Variable -Name 'IsWindows' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
        'Windows'
    }
    elseif (Get-Variable -Name 'IsMacOS' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
        'macOS'
    }
    elseif (Get-Variable -Name 'IsLinux' -ErrorAction 'SilentlyContinue' -ValueOnly ) {
        'Linux'
    }
    else {
        throw "Unsupported Operating system!"
    }
}

function Get-PSNowTempDirectory {
    if ((GetPSNowOs) -eq 'macOS') {
        # Special case for macOS using the real path instead of /tmp which is a symlink to this path
        "/private/tmp"
    }
    else {
        [System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    }
}

function Get-PSNowTempRegistry {
    $PSNowTempRegistryRoot = 'Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Software\PSNow'
    if (-not (Test-Path $PSNowTempRegistryRoot)) {
        try {
            $null = New-Item -Path $PSNowTempRegistryRoot -ErrorAction Stop
        }
        catch [Exception] {
            throw (New-Object Exception -ArgumentList "Was not able to create a Pester Registry key for TestRegistry", ($_.Exception))
        }
    }
    return $PSNowTempRegistryRoot
}