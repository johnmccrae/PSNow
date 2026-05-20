$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$moduleName = if (-not [string]::IsNullOrWhiteSpace($Env:BHProjectName)) { $Env:BHProjectName } else { 'PSNow' }
$resolvedModuleRoot = Join-Path $repoRoot ("Staging{0}{1}" -f [System.IO.Path]::DirectorySeparatorChar, $moduleName)
$moduleRoot = if (-not [string]::IsNullOrWhiteSpace($Env:BHModulePath)) {
    $Env:BHModulePath
}
elseif (Test-Path -Path $resolvedModuleRoot) {
    $resolvedModuleRoot
}
else {
    $repoRoot
}

Describe "General project validation: $moduleName" {
    Context "Are these valid PowerShell Scripts?"{

        $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse

        # TestCases are splatted to the script so we need hashtables
        $testCase = $scripts | Foreach-Object {@{file = $_}}
        It "Script <file> Should -be valid powershell" -TestCases $testCase {
            param($file)

            $file.fullname | Should -Exist

            $contents = Get-Content -Path $file.fullname -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
}
