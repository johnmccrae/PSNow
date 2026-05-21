function Invoke-WithRetry {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,

        [int]$MaxRetries = 3,

        [int]$InitialDelaySeconds = 2
    )

    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        try {
            & $Operation
            return
        } catch {
            $attempt++
            if ($attempt -ge $MaxRetries) {
                throw "Operation failed after $MaxRetries attempts: $_"
            }
            Start-Sleep -Seconds ($InitialDelaySeconds * [math]::Pow(2, $attempt - 1))
        }
    }
}