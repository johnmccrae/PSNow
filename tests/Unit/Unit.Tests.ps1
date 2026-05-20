$moduleName = 'PSNow'

Describe "Basic function unit tests" -Tags Build {

    It "Module '$moduleName' can import cleanly" {
        $repoRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        elseif (-not [string]::IsNullOrWhiteSpace($Env:BHProjectPath)) {
            $Env:BHProjectPath
        }
        else {
            (Get-Location).Path
        }

        $candidateModulePaths = @(
            (Join-Path $repoRoot 'Staging\PSNow\PSNow.psm1')
            (Join-Path $repoRoot 'PSNow.psm1')
        )

        $moduleFilePath = $candidateModulePaths | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
        $moduleFilePath | Should -Not -BeNullOrEmpty

        { Import-Module -Name $moduleFilePath -Force } | Should -Not -Throw
    }

}
