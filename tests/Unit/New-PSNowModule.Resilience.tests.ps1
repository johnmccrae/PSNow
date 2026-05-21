Describe "New-PSNowModule Resilience Tests" {
    BeforeAll {
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
    }

    It "Retries on transient failure and succeeds" {
        # Mock the operation to fail twice before succeeding
        $attempt = 0
        $mockOperation = {
            $attempt++
            if ($attempt -lt 3) {
                throw "Transient error"
            }
        }

        # Test the retry mechanism
        { Invoke-WithRetry -Operation $mockOperation -MaxRetries 3 -InitialDelaySeconds 1 } | Should -Not -Throw
    }

    It "Fails after maximum retries" {
        # Mock the operation to always fail
        $mockOperation = { throw "Persistent error" }

        # Test the retry mechanism
        { Invoke-WithRetry -Operation $mockOperation -MaxRetries 3 -InitialDelaySeconds 1 } | Should -Throw -ExpectedMessage "Operation failed after 3 attempts: Persistent error"
    }
}
