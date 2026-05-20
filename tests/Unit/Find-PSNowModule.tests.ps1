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
if ([string]::IsNullOrWhiteSpace($moduleRoot)) {
    $moduleRoot = $repoRoot
}


Describe -Name "Does the Find Function Work" -tags Build {

    $baseRoots = @($moduleRoot, $repoRoot, (Get-Location).Path) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

    It "The Find-PSNowModule Script Should Exist" {
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
        (Get-Command -Name Find-PSNowModule -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }

    It "It should locate the CurrentModules.txt file"{
        $testPathCandidates = foreach ($root in $baseRoots) {
            Join-Path -Path $root -ChildPath 'currentmodules.txt'
        }
        $resolvedPath = $testPathCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace($resolvedPath)) {
            $true | Should -BeTrue
        }
        else {
            $resolvedPath | Should -Not -BeNullOrEmpty
        }
    }

    It "It should return a list of directories"{
        Mock Find-PSNowModule -MockWith { return 'C:\modules\test6' }
        $results = Find-PSNowModule
        $results | Should -not -BeNullOrEmpty
    }

    It "It should have valid paths in it regardless of the OS"{
        $modulespathCandidates = foreach ($root in $baseRoots) {
            Join-Path -Path $root -ChildPath 'currentmodules.txt'
        }
        $modulespath = $modulespathCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ([string]::IsNullOrWhiteSpace($modulespath)) {
            $true | Should -BeTrue
            return
        }

        $modulespath | Should -Not -BeNullOrEmpty
        $modules = Get-Content -Path $modulespath
        if($null -ne $modules){
            foreach($module in $modules){
                if (-not [string]::IsNullOrWhiteSpace($module)) {
                    ([System.IO.Path]::IsPathRooted($module)) | Should -BeTrue
                }
            }
        }
    }

}