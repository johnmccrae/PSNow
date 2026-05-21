function Write-PSNowStructuredLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Fields
    )

    $parts = @("op=$Operation", "status=$Status")

    foreach ($entry in $Fields.GetEnumerator()) {
        $parts += "$($entry.Key)=$($entry.Value)"
    }

    Write-Verbose -Message ("[{0}]" -f ($parts -join ', '))
}
