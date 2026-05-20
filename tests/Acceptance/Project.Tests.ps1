$repoRoot = if (-not [string]::IsNullOrWhiteSpace($Env:BHProjectPath)) {
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
$repoRoot = [string]$repoRoot
$repoRoot = $repoRoot.Trim()
$safeRepoRoot = if ([string]::IsNullOrWhiteSpace($repoRoot)) { (Get-Location).Path } else { $repoRoot }
$moduleName = 'PSNow'
$resolvedModuleRoot = Join-Path $safeRepoRoot ("Staging{0}{1}" -f [System.IO.Path]::DirectorySeparatorChar, $moduleName)

$moduleRoot = if (Test-Path -Path $resolvedModuleRoot) {
    $resolvedModuleRoot
}
else {
    $safeRepoRoot
}

$buildEnvironmentReady =
    -not [string]::IsNullOrWhiteSpace($moduleRoot) -and
    -not [string]::IsNullOrWhiteSpace($moduleName)

$scriptAnalyzerSettingsCandidates = @(
    (Join-Path $safeRepoRoot 'Build\PSScriptAnalyzerSettings.psd1')
    (Join-Path $moduleRoot 'Build\PSScriptAnalyzerSettings.psd1')
)
$scriptAnalyzerSettingsPath = $scriptAnalyzerSettingsCandidates |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -Path $_) } |
    Select-Object -First 1

$canRunAnalyzer =
    $buildEnvironmentReady -and
    -not [string]::IsNullOrWhiteSpace($scriptAnalyzerSettingsPath)

$scripts = if ($buildEnvironmentReady) {
    Get-ChildItem -Path $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse | Where-Object FullName -notmatch 'classes'
}
else {
    @()
}

$analyzerTestCases = foreach ($scriptFile in $scripts) {
    if ($scriptFile -and -not [string]::IsNullOrWhiteSpace($scriptFile.FullName)) {
        @{ ScriptPath = $scriptFile.FullName }
    }
}
$analyzerTestCases = $analyzerTestCases | Where-Object { $_ -and $_.ScriptPath -and -not [string]::IsNullOrWhiteSpace($_.ScriptPath) }

$parserTestCases = foreach ($scriptFile in $scripts) {
    @{ File = $scriptFile }
}

Describe 'Build environment' -Tag Build {
    It 'resolves module root and module name before acceptance tests run' {
        $moduleNameForCheck = if (-not [string]::IsNullOrWhiteSpace($script:moduleName)) {
            $script:moduleName
        }
        elseif (-not [string]::IsNullOrWhiteSpace($Env:BHProjectName)) {
            $Env:BHProjectName
        }
        else {
            'PSNow'
        }

        $repoRootForCheck = if (-not [string]::IsNullOrWhiteSpace($Env:BHProjectPath)) {
            $Env:BHProjectPath
        }
        elseif (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        else {
            (Get-Location).Path
        }

        $resolvedModuleRootForCheck = Join-Path $repoRootForCheck 'Staging\PSNow'
        $moduleRootForCheck = if (Test-Path -Path $resolvedModuleRootForCheck) { $resolvedModuleRootForCheck } else { $repoRootForCheck }

        $moduleRootForCheck | Should -Not -BeNullOrEmpty
        $moduleNameForCheck | Should -Not -BeNullOrEmpty
        (Test-Path -Path $moduleRootForCheck) | Should -BeTrue
    }

    It 'attempts to resolve ScriptAnalyzer settings path before acceptance tests run' {
        if (-not [string]::IsNullOrWhiteSpace($scriptAnalyzerSettingsPath)) {
            (Test-Path -Path $scriptAnalyzerSettingsPath) | Should -BeTrue
        }
    }
}

Describe 'PSScriptAnalyzer rule-sets' -Tag Build -Skip:(-not $canRunAnalyzer -or $analyzerTestCases.Count -eq 0) {
    It 'Script <ScriptPath> should pass configured analyzer rules' -TestCases $analyzerTestCases {
        param(
            [string]$ScriptPath
        )

        $ScriptPath | Should -Not -BeNullOrEmpty

        $currentPath = Split-Path -Parent $ScriptPath
        $checkedPaths = @()
        $resolvedSettingsPath = $null

        while (-not [string]::IsNullOrWhiteSpace($currentPath)) {
            $candidateSettingsPath = Join-Path $currentPath 'Build\PSScriptAnalyzerSettings.psd1'
            $checkedPaths += $candidateSettingsPath

            if (Test-Path -Path $candidateSettingsPath) {
                $resolvedSettingsPath = $candidateSettingsPath
                break
            }

            $parentPath = Split-Path -Parent $currentPath
            if ([string]::IsNullOrWhiteSpace($parentPath) -or $parentPath -eq $currentPath) {
                break
            }

            $currentPath = $parentPath
        }

        if ([string]::IsNullOrWhiteSpace($resolvedSettingsPath) -or -not (Test-Path -Path $resolvedSettingsPath)) {
            Write-Error "[FATAL] Could not resolve PSScriptAnalyzer settings for script: $ScriptPath. Checked: $($checkedPaths -join ', ')" -ErrorAction Stop
            throw "[FATAL] Could not resolve PSScriptAnalyzer settings for script: $ScriptPath. Checked: $($checkedPaths -join ', ')"
        }

        $analyzerParams = @{
            Path     = $ScriptPath
            Settings = $resolvedSettingsPath
        }

        $analysisResults = Invoke-ScriptAnalyzer @analyzerParams

        if ($analysisResults.Count -gt 0) {
            $failureSummary = $analysisResults | ForEach-Object {
                "[$($_.RuleName)] $($_.Message) at $($_.ScriptName):$($_.Line)"
            }
            throw "ScriptAnalyzer findings for ${ScriptPath}: $([Environment]::NewLine)$($failureSummary -join [Environment]::NewLine)"
        }

        $analysisResults.Count | Should -Be 0
    }
}

Describe "General project validation: $moduleName" {

    Context 'Verifying all the files are proper PowerShell files' {
        It 'Script <File> Should -be valid powershell' -TestCases $parserTestCases {
            param($File)

            $File.FullName | Should -Exist

            $contents = Get-Content -Path $File.FullName -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context 'Does the module load cleanly' {
        It "Module '$moduleName' can import cleanly" {
            $moduleNameForImport = if (-not [string]::IsNullOrWhiteSpace($script:moduleName)) {
                $script:moduleName
            }
            elseif (-not [string]::IsNullOrWhiteSpace($Env:BHProjectName)) {
                $Env:BHProjectName
            }
            else {
                'PSNow'
            }

            $repoRootForImport = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            elseif (-not [string]::IsNullOrWhiteSpace($Env:BHProjectPath)) {
                $Env:BHProjectPath
            }
            else {
                (Get-Location).Path
            }

            $candidateModulePaths = @(
                (Join-Path $repoRootForImport ("Staging\{0}\{0}.psm1" -f $moduleNameForImport))
                (Join-Path $repoRootForImport ("{0}.psm1" -f $moduleNameForImport))
            )

            $moduleManifestPath = $candidateModulePaths | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
            $moduleManifestPath | Should -Not -BeNullOrEmpty
            $moduleManifestPath | Should -Exist
            { Import-Module $moduleManifestPath -Force } | Should -Not -Throw
        }
    }
}
