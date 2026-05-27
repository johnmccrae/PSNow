BeforeAll {
    $privatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Private\Invoke-PSNowWithRetry.ps1'
    . (Resolve-Path -Path $privatePath)
}

Describe "Invoke-PSNowWithRetry" {

    Context "Happy path" {
        It "Returns the operation result on first attempt" {
            $result = Invoke-PSNowWithRetry -Operation { 42 } -MaxRetries 3 -InitialDelayMs 0
            $result | Should -Be 42
        }

        It "Passes string output through unchanged" {
            $result = Invoke-PSNowWithRetry -Operation { 'hello' } -MaxRetries 3 -InitialDelayMs 0
            $result | Should -Be 'hello'
        }
    }

    Context "Retry behaviour" {
        It "Retries after a transient failure and returns on eventual success" {
            # Use a hashtable: properties are reference-safe across & $scriptblock calls.
            $state = @{ calls = 0 }
            $op = { $state.calls++; if ($state.calls -lt 3) { throw "flaky" } ; 'ok' }

            $result = Invoke-PSNowWithRetry -Operation $op -MaxRetries 3 -InitialDelayMs 0
            $result | Should -Be 'ok'
            $state.calls | Should -Be 3
        }

        It "Exhausts all attempts and throws with attempt count in message" {
            $op = { throw "always fails" }

            { Invoke-PSNowWithRetry -Operation $op -MaxRetries 3 -InitialDelayMs 0 } |
                Should -Throw -ExpectedMessage "*Operation failed after 3 attempt(s)*"
        }

        It "Respects MaxRetries — operation called exactly MaxRetries times" {
            $state = @{ calls = 0 }
            $op = { $state.calls++; throw "persistent" }

            { Invoke-PSNowWithRetry -Operation $op -MaxRetries 4 -InitialDelayMs 0 } |
                Should -Throw

            $state.calls | Should -Be 4
        }
    }

    Context "Exponential backoff" {
        It "Calls Start-Sleep with increasing delays" {
            Mock Start-Sleep {}
            $state = @{ calls = 0 }
            $op = { $state.calls++; if ($state.calls -lt 3) { throw "err" } }

            Invoke-PSNowWithRetry -Operation $op -MaxRetries 3 -InitialDelayMs 100 -BackoffMultiplier 2.0

            # Two failures → two sleeps: 100ms then 200ms
            Assert-MockCalled Start-Sleep -Times 2 -Exactly
        }

        It "Does not call Start-Sleep when InitialDelayMs is 0" {
            Mock Start-Sleep {}
            $op = { throw "fail" }

            { Invoke-PSNowWithRetry -Operation $op -MaxRetries 2 -InitialDelayMs 0 } |
                Should -Throw

            Assert-MockCalled Start-Sleep -Times 0 -Exactly
        }
    }

    Context "RetryOnExceptionType filter" {
        It "Retries only matching exception type and succeeds" {
            $state = @{ calls = 0 }
            $op = {
                $state.calls++
                if ($state.calls -lt 3) { throw [System.IO.IOException]::new("locked") }
                'done'
            }

            $result = Invoke-PSNowWithRetry -Operation $op -MaxRetries 3 -InitialDelayMs 0 `
                -RetryOnExceptionType @([System.IO.IOException])
            $result | Should -Be 'done'
        }

        It "Rethrows immediately on non-matching exception type without retrying" {
            $state = @{ calls = 0 }
            $op = {
                $state.calls++
                throw [System.InvalidOperationException]::new("logic error")
            }

            { Invoke-PSNowWithRetry -Operation $op -MaxRetries 5 -InitialDelayMs 0 `
                -RetryOnExceptionType @([System.IO.IOException]) } |
                Should -Throw -ExpectedMessage "*logic error*"

            # Must NOT retry — only 1 call despite MaxRetries=5
            $state.calls | Should -Be 1
        }

        It "Retries on any exception when RetryOnExceptionType is empty" {
            $state = @{ calls = 0 }
            $op = { $state.calls++; if ($state.calls -lt 2) { throw "any error" } ; 'ok' }

            $result = Invoke-PSNowWithRetry -Operation $op -MaxRetries 3 -InitialDelayMs 0
            $result | Should -Be 'ok'
            $state.calls | Should -Be 2
        }
    }
}
