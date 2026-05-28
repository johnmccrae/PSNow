function Write-PSNowStructuredLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Fields
    )

    $strictMode = Get-PSNowFeatureFlag -Name 'StrictLogSanitization'

    $parts = @("op=$Operation", "status=$Status")

    foreach ($entry in $Fields.GetEnumerator()) {
        $value = [string]$entry.Value
        if ($strictMode -and ($value -match '[],=\s]')) {
            $value = '"' + $value.Replace('"', '\"') + '"'
        }
        $parts += "$($entry.Key)=$value"
    }

    Write-Verbose -Message ("[{0}]" -f ($parts -join ', '))
}
