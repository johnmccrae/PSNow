$repoRoot = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    Split-Path -Parent (Split-Path -Parent $PSCommandPath)
}
elseif (-not [string]::IsNullOrWhiteSpace($Env:BHProjectPath)) {
    $Env:BHProjectPath
}
elseif (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
else {
    (Get-Location).Path
}
if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    $repoRoot = (Get-Location).Path
}

$moduleRoot = if (-not [string]::IsNullOrWhiteSpace($Env:BHModulePath) -and (Test-Path -Path $Env:BHModulePath)) {
    $Env:BHModulePath
}
else {
    $repoRoot
}


Describe -Name "New-PSNowModule Tests" {

    $baseRoots = @($moduleRoot, $repoRoot, (Get-Location).Path) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

    It "The New-PSNowModule Script Should Exist"{
        $manifestPathCandidates = foreach ($root in $baseRoots) {
            Join-Path -Path $root -ChildPath 'PSNow.psd1'
        }
        $manifestPath = $manifestPathCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($manifestPath)) {
            $manifestPath = Get-ChildItem -Path (Get-Location).Path -Filter 'PSNow.psd1' -Recurse -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName -First 1
        }

        $manifestPath | Should -Not -BeNullOrEmpty
        Import-Module -Name $manifestPath -Force -ErrorAction SilentlyContinue
        (Get-Command -Name New-PSNowModule -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }

    It 'It should accept 3 parameters'{
        Mock New-PSNowModule -ParameterFilter { $NewModuleName -eq 'Testing' -and $BaseManifest -eq 'Advanced' -and $ModuleRoot -eq 'c:\modules' } -MockWith { $true }
        $null = New-PSNowModule -NewModuleName 'testing' -BaseManifest 'Advanced' -ModuleRoot 'c:\modules'
        Should -Invoke New-PSNowModule -ParameterFilter { $NewModuleName -eq 'Testing' -and $BaseManifest -eq 'Advanced' -and $ModuleRoot -eq 'c:\modules' } -Exactly 1 -Scope It
    }

}

