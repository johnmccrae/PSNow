function Get-PSNowFeatureFlag {
    <#
    .SYNOPSIS
    Returns the enabled state of a named PSNow feature flag.

    .DESCRIPTION
    Reads the environment variable PSNOW_<FLAGNAME> (uppercased) and returns
    $true when the flag is enabled, $false when disabled.

    Naming convention: PSNOW_<FLAG_NAME_UPPERCASE>
      e.g. Get-PSNowFeatureFlag -Name 'StructuredLogging'
           reads $env:PSNOW_STRUCTURED_LOGGING

    Default state is ON: if the variable is unset or empty the flag is considered
    enabled. Set the variable to '0', 'false', or 'no' (case-insensitive) to
    disable.

    .PARAMETER Name
    The feature flag name in PascalCase (e.g. 'StructuredLogging').
    The function converts it to SCREAMING_SNAKE_CASE automatically.

    .EXAMPLE
    if (Get-PSNowFeatureFlag -Name 'StructuredLogging') {
        Write-PSNowStructuredLog ...
    }

    .EXAMPLE
    $env:PSNOW_STRUCTURED_LOGGING = '0'
    Get-PSNowFeatureFlag -Name 'StructuredLogging'   # returns $false
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    # Convert PascalCase to SCREAMING_SNAKE_CASE: insert _ before each uppercase
    # letter that follows a lowercase letter, then uppercase the whole string.
    $envName = 'PSNOW_' + ($Name -creplace '(?<=[a-z])([A-Z])', '_$1').ToUpper()
    $value   = [System.Environment]::GetEnvironmentVariable($envName)

    # Unset or empty = disabled (default OFF — new behaviour must be explicitly opted in to)
    if ([string]::IsNullOrWhiteSpace($value)) { return $false }

    return $value -notin @('0', 'false', 'no')
}
