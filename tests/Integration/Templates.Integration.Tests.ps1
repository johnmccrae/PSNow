<#
.SYNOPSIS
    Integration tests that invoke each PSNow Plaster template and verify the
    generated module contains the correct files and content.

.DESCRIPTION
    For each of the three template tiers (Basic, Extended, Advanced) these tests:
      - Copy the selected XML to PlasterManifest.xml at the PSNow root (mirroring
        what New-PSNowModule does), then call Invoke-Plaster directly.
      - Assert every expected file and folder was created in the temp output directory.
      - Assert Plaster's EJS-style template substitution placed the module name in
        key templateFile outputs.
      - Assert that files specific to higher tiers are absent from lower-tier output.
      - Validate the generated .psd1 via Test-ModuleManifest.

    Requirements: Plaster must be installed.
      Install-PSResource -Name Plaster -Version 1.1.3

    The requireModule elements in Extended.xml / Advanced.xml (psake, Pester,
    Microsoft.PowerShell.PlatyPS) emit advisory warnings in Plaster but do NOT
    stop template execution, so those modules are not required to run these tests.

.NOTES
    All output is written to a per-run temp folder that is removed in AfterAll.
    PlasterManifest.xml is written to the PSNow repo root during each Describe
    block and removed in that block's AfterAll.  Tests run sequentially so there
    is no shared-state race condition within a single Pester run.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

# ---------------------------------------------------------------------------
# Discovery-time skip guard  (-Skip is evaluated before BeforeAll runs)
# ---------------------------------------------------------------------------
$plasterAvailable = $null -ne (Get-Module -ListAvailable -Name 'Plaster' -ErrorAction SilentlyContinue)

BeforeAll {
    $script:PSNowRoot = (Resolve-Path "$PSScriptRoot\..\.." -ErrorAction Stop).Path
    # Unique per-run folder prevents collision on rapid reruns or parallel agents
    $script:TempBase  = Join-Path ([System.IO.Path]::GetTempPath()) "PSNowInteg_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -Path $script:TempBase -ItemType Directory -Force | Out-Null
}

AfterAll {
    if ($script:TempBase -and (Test-Path $script:TempBase)) {
        Remove-Item $script:TempBase -Recurse -Force -ErrorAction SilentlyContinue
    }
    $mf = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
    if (Test-Path $mf) { Remove-Item $mf -Force -ErrorAction SilentlyContinue }
}


# =============================================================================
# BASIC TEMPLATE
# =============================================================================
Describe 'Basic template — generated module structure' -Skip:(-not $plasterAvailable) {

    BeforeAll {
        $modName = 'PSNowIntegBasic'
        $outDir  = Join-Path $script:TempBase 'Basic'
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null

        Copy-Item "$($script:PSNowRoot)\PlasterTemplate\Basic.xml" `
                  "$($script:PSNowRoot)\PlasterManifest.xml" -Force

        Invoke-Plaster `
            -TemplatePath      $script:PSNowRoot `
            -DestinationPath   $outDir `
            -ModuleName        $modName `
            -ModuleAuthor      'Test Author' `
            -ModuleVersion     '0.1.0' `
            -CompanyName       'Test Org' `
            -Description       'Integration test module' `
            -GitHubUserName    'testuser' `
            -GitHubRepo        'testrepo' `
            -PowerShellVersion '5.1' `
            -Force -NoLogo -ErrorAction Stop

        $modRoot = Join-Path $outDir $modName
    }

    AfterAll {
        $mf = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
        if (Test-Path $mf) { Remove-Item $mf -Force -ErrorAction SilentlyContinue }
    }

    Context 'Core module files' {
        It 'Creates <name>.psd1'                        { "$modRoot\$modName.psd1"          | Should -Exist }
        It 'Creates <name>.psm1'                        { "$modRoot\$modName.psm1"          | Should -Exist }
        It 'Creates Public\<name>.ps1 starter function' { "$modRoot\Public\$modName.ps1"    | Should -Exist }
        It 'Creates LICENSE.md'                         { "$modRoot\LICENSE.md"             | Should -Exist }
        It 'Creates README.md'                          { "$modRoot\README.md"              | Should -Exist }
        It 'Creates .gitignore'                         { "$modRoot\.gitignore"             | Should -Exist }
    }

    Context 'Module folders' {
        It 'Creates Public folder'        { "$modRoot\Public"        | Should -Exist }
        It 'Creates Private folder'       { "$modRoot\Private"       | Should -Exist }
        It 'Creates Documentation folder' { "$modRoot\Documentation" | Should -Exist }
    }

    Context 'Module manifest validity' {
        BeforeAll {
            $manifest = Test-ModuleManifest -Path "$modRoot\$modName.psd1" -ErrorAction SilentlyContinue
        }
        It 'Manifest passes Test-ModuleManifest'        { { Test-ModuleManifest -Path "$modRoot\$modName.psd1" -ErrorAction Stop } | Should -Not -Throw }
        It 'Manifest name matches the requested name'   { $manifest.Name       | Should -Be $modName }
        It 'Manifest version matches the requested version' { $manifest.Version | Should -Be '0.1.0' }
        It 'Manifest RootModule references the psm1'   { $manifest.RootModule | Should -Be "$modName.psm1" }
    }

    Context 'AI scaffolding' {
        It 'Creates .github folder'                     { "$modRoot\.github"                         | Should -Exist }
        It 'Creates .github\copilot-instructions.md'    { "$modRoot\.github\copilot-instructions.md" | Should -Exist }
        It 'copilot-instructions.md contains the module name' {
            Get-Content "$modRoot\.github\copilot-instructions.md" -Raw | Should -Match $modName
        }
    }

    Context 'Template substitution' {
        It 'Starter function contains the module name' {
            Get-Content "$modRoot\Public\$modName.ps1" -Raw | Should -Match $modName
        }
        It 'psm1 is parseable PowerShell' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content "$modRoot\$modName.psm1"), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context 'Does not include Extended/Advanced-only files' {
        It 'No Build folder'   { "$modRoot\Build"    | Should -Not -Exist }
        It 'No Tests folder'   { "$modRoot\Tests"    | Should -Not -Exist }
        It 'No Spec folder'    { "$modRoot\Spec"     | Should -Not -Exist }
        It 'No Help folder'    { "$modRoot\Help"     | Should -Not -Exist }
        It 'No AGENTS.md'      { "$modRoot\AGENTS.md" | Should -Not -Exist }
        It 'No CLAUDE.md'      { "$modRoot\CLAUDE.md" | Should -Not -Exist }
    }
}


# =============================================================================
# EXTENDED TEMPLATE
# =============================================================================
Describe 'Extended template — generated module structure' -Skip:(-not $plasterAvailable) {

    BeforeAll {
        $modName = 'PSNowIntegExtended'
        $outDir  = Join-Path $script:TempBase 'Extended'
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null

        Copy-Item "$($script:PSNowRoot)\PlasterTemplate\Extended.xml" `
                  "$($script:PSNowRoot)\PlasterManifest.xml" -Force

        # FunctionFolders default (0,3) = Public + Private
        Invoke-Plaster `
            -TemplatePath      $script:PSNowRoot `
            -DestinationPath   $outDir `
            -ModuleName        $modName `
            -ModuleAuthor      'Test Author' `
            -ModuleVersion     '0.1.0' `
            -CompanyName       'Test Org' `
            -Description       'Integration test module' `
            -GitHubUserName    'testuser' `
            -GitHubRepo        'testrepo' `
            -PowerShellVersion '5.1' `
            -FunctionFolders   @('Public', 'Private') `
            -Force -NoLogo -ErrorAction Stop

        $modRoot = Join-Path $outDir $modName
    }

    AfterAll {
        $mf = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
        if (Test-Path $mf) { Remove-Item $mf -Force -ErrorAction SilentlyContinue }
    }

    Context 'Core module files' {
        It 'Creates <name>.psd1'                        { "$modRoot\$modName.psd1"       | Should -Exist }
        It 'Creates <name>.psm1'                        { "$modRoot\$modName.psm1"       | Should -Exist }
        It 'Creates <name>.nuspec'                      { "$modRoot\$modName.nuspec"     | Should -Exist }
        It 'Creates Public\<name>.ps1 starter function' { "$modRoot\Public\$modName.ps1" | Should -Exist }
        It 'Creates LICENSE.md'                         { "$modRoot\LICENSE.md"          | Should -Exist }
        It 'Creates README.md'                          { "$modRoot\README.md"           | Should -Exist }
        It 'Creates .gitignore'                         { "$modRoot\.gitignore"          | Should -Exist }
    }

    Context 'Module folders' {
        It 'Creates Public folder'        { "$modRoot\Public"        | Should -Exist }
        It 'Creates Private folder'       { "$modRoot\Private"       | Should -Exist }
        It 'Creates Documentation folder' { "$modRoot\Documentation" | Should -Exist }
        It 'Creates Certs folder'         { "$modRoot\Certs"         | Should -Exist }
    }

    Context 'Module manifest validity' {
        BeforeAll {
            $manifest = Test-ModuleManifest -Path "$modRoot\$modName.psd1" -ErrorAction SilentlyContinue
        }
        It 'Manifest passes Test-ModuleManifest'            { { Test-ModuleManifest -Path "$modRoot\$modName.psd1" -ErrorAction Stop } | Should -Not -Throw }
        It 'Manifest name matches the requested name'       { $manifest.Name       | Should -Be $modName }
        It 'Manifest version matches the requested version' { $manifest.Version    | Should -Be '0.1.0' }
        It 'Manifest RootModule references the psm1'        { $manifest.RootModule | Should -Be "$modName.psm1" }
    }

    Context 'VS Code support' {
        It 'Creates .vscode folder'        { "$modRoot\.vscode"              | Should -Exist }
        It 'Creates .vscode\settings.json' { "$modRoot\.vscode\settings.json" | Should -Exist }
        It 'Creates .vscode\task.json'     { "$modRoot\.vscode\task.json"     | Should -Exist }
    }

    Context 'Build tooling' {
        It 'Creates Build folder'                        { "$modRoot\Build"                               | Should -Exist }
        It 'Creates Build\build.ps1'                     { "$modRoot\Build\build.ps1"                     | Should -Exist }
        It 'Creates Build\build.depend.psd1'             { "$modRoot\Build\build.depend.psd1"             | Should -Exist }
        It 'Creates Build\build.psake.ps1'               { "$modRoot\Build\build.psake.ps1"               | Should -Exist }
        It 'Creates Build\deploy.psdeploy.ps1'           { "$modRoot\Build\deploy.psdeploy.ps1"           | Should -Exist }
        It 'Creates Build\PSScriptAnalyzerSettings.psd1' { "$modRoot\Build\PSScriptAnalyzerSettings.psd1" | Should -Exist }
    }

    Context 'Pester test structure' {
        It 'Creates Tests folder'                         { "$modRoot\Tests"                              | Should -Exist }
        It 'Creates Tests\Unit folder'                    { "$modRoot\Tests\Unit"                         | Should -Exist }
        It 'Creates Tests\Common folder'                  { "$modRoot\Tests\Common"                       | Should -Exist }
        It 'Creates Tests\Unit\Unit.Tests.ps1'            { "$modRoot\Tests\Unit\Unit.Tests.ps1"           | Should -Exist }
        It 'Creates Tests\Common\Basic.tests.ps1'         { "$modRoot\Tests\Common\Basic.tests.ps1"        | Should -Exist }
        It 'Creates Tests\Common\Environment.tests.ps1'   { "$modRoot\Tests\Common\Environment.tests.ps1"  | Should -Exist }
        It 'Creates Tests\Common\Help.Tests.ps1'          { "$modRoot\Tests\Common\Help.Tests.ps1"         | Should -Exist }
        It 'Creates Tests\Common\Manifest.Tests.ps1'      { "$modRoot\Tests\Common\Manifest.Tests.ps1"     | Should -Exist }
    }

    Context 'AI scaffolding' {
        It 'Creates .github folder'                  { "$modRoot\.github"                         | Should -Exist }
        It 'Creates .github\copilot-instructions.md' { "$modRoot\.github\copilot-instructions.md" | Should -Exist }
        It 'Creates AGENTS.md'                       { "$modRoot\AGENTS.md"                       | Should -Exist }
        It 'copilot-instructions.md contains the module name' {
            Get-Content "$modRoot\.github\copilot-instructions.md" -Raw | Should -Match $modName
        }
        It 'AGENTS.md contains the module name' {
            Get-Content "$modRoot\AGENTS.md" -Raw | Should -Match $modName
        }
    }

    Context 'Template substitution' {
        It 'nuspec contains the module name' {
            Get-Content "$modRoot\$modName.nuspec" -Raw | Should -Match $modName
        }
        It 'build.psake.ps1 is parseable PowerShell' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content "$modRoot\Build\build.psake.ps1"), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context 'Does not include Advanced-only files' {
        It 'No CLAUDE.md'   { "$modRoot\CLAUDE.md" | Should -Not -Exist }
        It 'No Spec folder' { "$modRoot\Spec"      | Should -Not -Exist }
        It 'No Help folder' { "$modRoot\Help"      | Should -Not -Exist }
    }
}


# =============================================================================
# ADVANCED TEMPLATE
# =============================================================================
Describe 'Advanced template — generated module structure' -Skip:(-not $plasterAvailable) {

    BeforeAll {
        $modName = 'PSNowIntegAdvanced'
        $outDir  = Join-Path $script:TempBase 'Advanced'
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null

        Copy-Item "$($script:PSNowRoot)\PlasterTemplate\Advanced.xml" `
                  "$($script:PSNowRoot)\PlasterManifest.xml" -Force

        # FunctionFolders default (0,3) = Public + Private
        # Options default (1-5) = Git, psake, Pester, PSScriptAnalyzer, platyPS
        Invoke-Plaster `
            -TemplatePath      $script:PSNowRoot `
            -DestinationPath   $outDir `
            -ModuleName        $modName `
            -ModuleAuthor      'Test Author' `
            -ModuleVersion     '0.1.0' `
            -CompanyName       'Test Org' `
            -Description       'Integration test module' `
            -GitHubUserName    'testuser' `
            -GitHubRepo        'testrepo' `
            -PowerShellVersion '5.1' `
            -FunctionFolders   @('Public', 'Private') `
            -Options           @('Git', 'psake', 'Pester', 'PSScriptAnalyzer', 'platyPS') `
            -Force -NoLogo -ErrorAction Stop

        $modRoot = Join-Path $outDir $modName
    }

    AfterAll {
        $mf = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
        if (Test-Path $mf) { Remove-Item $mf -Force -ErrorAction SilentlyContinue }
    }

    Context 'Core module files' {
        It 'Creates <name>.psd1'                        { "$modRoot\$modName.psd1"       | Should -Exist }
        It 'Creates <name>.psm1'                        { "$modRoot\$modName.psm1"       | Should -Exist }
        It 'Creates <name>.nuspec'                      { "$modRoot\$modName.nuspec"     | Should -Exist }
        It 'Creates Public\<name>.ps1 starter function' { "$modRoot\Public\$modName.ps1" | Should -Exist }
        It 'Creates LICENSE.md'                         { "$modRoot\LICENSE.md"          | Should -Exist }
        # Advanced.xml uses 'Readme.md' (mixed case) — intentional difference from Basic/Extended
        It 'Creates Readme.md'                          { "$modRoot\Readme.md"           | Should -Exist }
        It 'Creates .gitignore (Options includes Git)'  { "$modRoot\.gitignore"          | Should -Exist }
    }

    Context 'Module folders' {
        It 'Creates Public folder'        { "$modRoot\Public"        | Should -Exist }
        It 'Creates Private folder'       { "$modRoot\Private"       | Should -Exist }
        It 'Creates Documentation folder' { "$modRoot\Documentation" | Should -Exist }
    }

    Context 'Module manifest validity' {
        BeforeAll {
            $manifest = Test-ModuleManifest -Path "$modRoot\$modName.psd1" -ErrorAction SilentlyContinue
        }
        It 'Manifest passes Test-ModuleManifest'            { { Test-ModuleManifest -Path "$modRoot\$modName.psd1" -ErrorAction Stop } | Should -Not -Throw }
        It 'Manifest name matches the requested name'       { $manifest.Name       | Should -Be $modName }
        It 'Manifest version matches the requested version' { $manifest.Version    | Should -Be '0.1.0' }
        It 'Manifest RootModule references the psm1'        { $manifest.RootModule | Should -Be "$modName.psm1" }
    }

    Context 'Spec (Gherkin) folder — unconditional in Advanced' {
        It 'Creates Spec folder'             { "$modRoot\Spec"                        | Should -Exist }
        It 'Creates Spec\<name>.feature'     { "$modRoot\Spec\$modName.feature"       | Should -Exist }
        It 'Creates Spec\<name>.Steps.ps1'   { "$modRoot\Spec\$modName.Steps.ps1"     | Should -Exist }
    }

    Context 'VS Code support' {
        It 'Creates .vscode folder'        { "$modRoot\.vscode"               | Should -Exist }
        It 'Creates .vscode\settings.json' { "$modRoot\.vscode\settings.json"  | Should -Exist }
        It 'Creates .vscode\task.json'     { "$modRoot\.vscode\task.json"      | Should -Exist }
    }

    Context 'Build tooling (Options includes psake)' {
        It 'Creates Build folder'                        { "$modRoot\Build"                               | Should -Exist }
        It 'Creates Build\build.ps1'                     { "$modRoot\Build\build.ps1"                     | Should -Exist }
        It 'Creates Build\build.depend.psd1'             { "$modRoot\Build\build.depend.psd1"             | Should -Exist }
        It 'Creates Build\build.psake.ps1'               { "$modRoot\Build\build.psake.ps1"               | Should -Exist }
        It 'Creates Build\deploy.psdeploy.ps1'           { "$modRoot\Build\deploy.psdeploy.ps1"           | Should -Exist }
        It 'Creates Certs folder'                        { "$modRoot\Certs"                               | Should -Exist }
        It 'Creates Certs\openssl.cfg'                   { "$modRoot\Certs\openssl.cfg"                   | Should -Exist }
    }

    Context 'Script analysis support (Options includes PSScriptAnalyzer)' {
        It 'Creates Build\PSScriptAnalyzerSettings.psd1' { "$modRoot\Build\PSScriptAnalyzerSettings.psd1" | Should -Exist }
    }

    Context 'Pester test structure (Options includes Pester)' {
        It 'Creates Tests folder'                            { "$modRoot\Tests"                                   | Should -Exist }
        It 'Creates Tests\Unit folder'                       { "$modRoot\Tests\Unit"                              | Should -Exist }
        It 'Creates Tests\Common folder'                     { "$modRoot\Tests\Common"                            | Should -Exist }
        It 'Creates Tests\Acceptance folder'                 { "$modRoot\Tests\Acceptance"                        | Should -Exist }
        It 'Creates Tests\Unit\Unit.Tests.ps1'               { "$modRoot\Tests\Unit\Unit.Tests.ps1"                | Should -Exist }
        It 'Creates Tests\Common\Basic.tests.ps1'            { "$modRoot\Tests\Common\Basic.tests.ps1"             | Should -Exist }
        It 'Creates Tests\Common\Environment.tests.ps1'      { "$modRoot\Tests\Common\Environment.tests.ps1"       | Should -Exist }
        It 'Creates Tests\Common\Help.Tests.ps1'             { "$modRoot\Tests\Common\Help.Tests.ps1"              | Should -Exist }
        It 'Creates Tests\Common\Manifest.Tests.ps1'         { "$modRoot\Tests\Common\Manifest.Tests.ps1"          | Should -Exist }
        It 'Creates Tests\Common\PSSA.Tests.wip.ps1'         { "$modRoot\Tests\Common\PSSA.Tests.wip.ps1"          | Should -Exist }
        It 'Creates Tests\Common\Analyzer.tests.ps1.example' { "$modRoot\Tests\Common\Analyzer.tests.ps1.example"  | Should -Exist }
        It 'Creates Tests\Acceptance\Project.Tests.ps1'      { "$modRoot\Tests\Acceptance\Project.Tests.ps1"       | Should -Exist }
    }

    Context 'PlatyPS help support (Options includes platyPS)' {
        It 'Creates Help folder'                     { "$modRoot\Help"                              | Should -Exist }
        It "Creates Help\about_<name>.help.md"       { "$modRoot\Help\about_$modName.help.md"       | Should -Exist }
    }

    Context 'AI scaffolding' {
        It 'Creates .github folder'                  { "$modRoot\.github"                         | Should -Exist }
        It 'Creates .github\copilot-instructions.md' { "$modRoot\.github\copilot-instructions.md" | Should -Exist }
        It 'Creates AGENTS.md'                       { "$modRoot\AGENTS.md"                       | Should -Exist }
        It 'Creates CLAUDE.md'                       { "$modRoot\CLAUDE.md"                       | Should -Exist }
        It 'copilot-instructions.md contains the module name' {
            Get-Content "$modRoot\.github\copilot-instructions.md" -Raw | Should -Match $modName
        }
        It 'AGENTS.md contains the module name' {
            Get-Content "$modRoot\AGENTS.md" -Raw | Should -Match $modName
        }
        It 'CLAUDE.md contains the module name' {
            Get-Content "$modRoot\CLAUDE.md" -Raw | Should -Match $modName
        }
    }

    Context 'Template substitution' {
        It 'nuspec contains the module name' {
            Get-Content "$modRoot\$modName.nuspec" -Raw | Should -Match $modName
        }
        It 'build.psake.ps1 is parseable PowerShell' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content "$modRoot\Build\build.psake.ps1"), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
}
