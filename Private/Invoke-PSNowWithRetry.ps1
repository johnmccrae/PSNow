function Invoke-PSNowWithRetry {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [object[]]$ArgumentList = @(),

        [Parameter()]
        [int]$MaxAttempts = 3,

        [Parameter()]
        [int]$InitialDelayMs = 500,

        [Parameter()]
        [double]$BackoffMultiplier = 2.0,

        [Parameter()]
        [double]$TimeoutSeconds = 0,

        [Parameter()]
        [string]$OperationName = 'operation'
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $attempt   = 0
    $delayMs   = $InitialDelayMs

    while ($attempt -lt $MaxAttempts) {

        if ($TimeoutSeconds -gt 0 -and $stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
            Write-PSNowStructuredLog -Operation $OperationName -Status 'timeout' -Fields ([ordered]@{
                elapsed_s = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
                timeout_s = $TimeoutSeconds
                attempts  = $attempt
            })
            throw [System.TimeoutException]::new(
                "Operation '$OperationName' exceeded timeout of $TimeoutSeconds second(s) after $attempt attempt(s).")
        }

        $attempt++

        Write-PSNowStructuredLog -Operation $OperationName -Status 'attempt' -Fields ([ordered]@{
            attempt      = $attempt
            max_attempts = $MaxAttempts
        })

        try {
            $result = & $ScriptBlock @ArgumentList

            Write-PSNowStructuredLog -Operation $OperationName -Status 'succeeded' -Fields ([ordered]@{
                attempt    = $attempt
                elapsed_ms = $stopwatch.ElapsedMilliseconds
            })

            return $result
        }
        catch {
            Write-PSNowStructuredLog -Operation $OperationName -Status 'error' -Fields ([ordered]@{
                attempt = $attempt
                error   = $_.Exception.Message
            })

            if ($attempt -ge $MaxAttempts) {
                Write-PSNowStructuredLog -Operation $OperationName -Status 'failed' -Fields ([ordered]@{
                    attempts   = $attempt
                    elapsed_ms = $stopwatch.ElapsedMilliseconds
                })
                throw
            }

            # Trim sleep to remaining budget so we don't over-sleep past the timeout.
            $actualDelayMs = $delayMs
            if ($TimeoutSeconds -gt 0) {
                $remainingMs = [int](($TimeoutSeconds * 1000) - $stopwatch.ElapsedMilliseconds)
                if ($remainingMs -le 0) {
                    Write-PSNowStructuredLog -Operation $OperationName -Status 'timeout' -Fields ([ordered]@{
                        elapsed_s = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
                        timeout_s = $TimeoutSeconds
                        attempts  = $attempt
                    })
                    throw [System.TimeoutException]::new(
                        "Operation '$OperationName' exceeded timeout of $TimeoutSeconds second(s) after $attempt attempt(s).")
                }
                $actualDelayMs = [math]::Min($delayMs, $remainingMs)
            }

            Write-PSNowStructuredLog -Operation $OperationName -Status 'retry' -Fields ([ordered]@{
                attempt  = $attempt
                delay_ms = $actualDelayMs
            })

            Start-Sleep -Milliseconds $actualDelayMs
            $delayMs = [int]($delayMs * $BackoffMultiplier)
        }
    }
}
