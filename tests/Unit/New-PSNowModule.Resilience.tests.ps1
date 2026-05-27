Describe "New-PSNowModule Resilience Tests" {
    BeforeAll {
        # Load the real Private helper so tests exercise production code.
        $privatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Private\Invoke-PSNowWithRetry.ps1'
        . (Resolve-Path -Path $privatePath)
    }

    It "Retries on transient failure and eventually succeeds" {
        $state = @{ callCount = 0 }
        $op = { $state.callCount++; if ($state.callCount -lt 3) { throw "Transient error" } }

        # MaxRetries=3, InitialDelayMs=0 to avoid wall-clock delay in tests.
        { Invoke-PSNowWithRetry -Operation $op -MaxRetries 3 -InitialDelayMs 0 } | Should -Not -Throw
        $state.callCount | Should -Be 3
    }

    It "Throws after all attempts are exhausted" {
        $op = { throw "Persistent error" }

        { Invoke-PSNowWithRetry -Operation $op -MaxRetries 3 -InitialDelayMs 0 } |
            Should -Throw -ExpectedMessage "*Operation failed after 3 attempt(s)*"
    }
}
