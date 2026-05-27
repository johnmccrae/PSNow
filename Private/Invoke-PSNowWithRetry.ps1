<#
.SYNOPSIS
Executes a scriptblock with retry and exponential backoff.

.DESCRIPTION
Invoke-PSNowWithRetry runs the given Operation up to MaxRetries total
attempts. On each failure the helper sleeps for the current delay, then
multiplies the delay by BackoffMultiplier before the next attempt.

If RetryOnExceptionType is supplied, only exceptions whose type is
assignable to one of the listed types trigger a retry; all others
re-throw immediately.

Tuning parameters
-----------------
MaxRetries         : Total attempts (including the first). Default: 3.
                     Increase for highly transient resources (e.g. 5).
InitialDelayMs     : Sleep before the 2nd attempt, in milliseconds.
                     Default: 500. Set to 0 in tests to avoid wall-clock
                     delays.
BackoffMultiplier  : Factor applied to the delay after each failure.
                     Default: 2.0 (exponential). Use 1.0 for linear
                     (constant) backoff.
RetryOnExceptionType: Array of [type] objects. Empty (default) retries
                     on any exception. Restrict to e.g.
                     @([System.IO.IOException]) to avoid retrying logic
                     errors.

Rollback guidance
-----------------
If wrapping a call with Invoke-PSNowWithRetry causes unexpected
behaviour, remove the wrapper and restore the direct call. No state is
mutated by this helper.

.EXAMPLE
Invoke-PSNowWithRetry -Operation { Get-Content -Path $path } -MaxRetries 3

.EXAMPLE
Invoke-PSNowWithRetry -Operation { Invoke-WebRequest -Uri $uri } `
    -MaxRetries 5 -InitialDelayMs 1000 -BackoffMultiplier 2.0 `
    -RetryOnExceptionType @([System.Net.WebException])
#>
function Invoke-PSNowWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Operation,

        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3,

        [ValidateRange(0, 60000)]
        [int]$InitialDelayMs = 500,

        [ValidateRange(1.0, 10.0)]
        [double]$BackoffMultiplier = 2.0,

        [type[]]$RetryOnExceptionType = @()
    )

    $attempt = 0
    $delayMs  = $InitialDelayMs

    while ($attempt -lt $MaxRetries) {
        try {
            return (& $Operation)
        }
        catch {
            $caught = $_

            # Honour RetryOnExceptionType filter when provided.
            if ($RetryOnExceptionType.Count -gt 0) {
                $exType     = $caught.Exception.GetType()
                $matchFound = $RetryOnExceptionType |
                    Where-Object { $_.IsAssignableFrom($exType) } |
                    Select-Object -First 1
                if (-not $matchFound) {
                    throw
                }
            }

            $attempt++

            if ($attempt -ge $MaxRetries) {
                throw "Operation failed after $MaxRetries attempt(s): $caught"
            }

            Write-Verbose ("Invoke-PSNowWithRetry: attempt {0} failed ({1}). " +
                "Retrying in {2}ms (backoff x{3})." -f
                $attempt, $caught.Exception.Message, $delayMs, $BackoffMultiplier)

            if ($delayMs -gt 0) {
                Start-Sleep -Milliseconds $delayMs
            }
            $delayMs = [int]($delayMs * $BackoffMultiplier)
        }
    }
}
