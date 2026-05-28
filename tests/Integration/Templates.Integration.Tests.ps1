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
    $script:PSNowRoot = (Resolve-Path (Join-Path $PSScriptRoot ".." "..") -ErrorAction Stop).Path
    # Unique per-run folder prevents collision on rapid reruns or parallel agents
    $script:TempBase  = Join-Path ([System.IO.Path]::GetTempPath()) "PSNowInteg_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -Path $script:TempBase -ItemType Directory -Force | Out-Null

    # Preserve the original PlasterManifest.xml so it can be restored after tests
    $mfOriginal = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
    $script:OriginalManifestContent = if (Test-Path $mfOriginal) { Get-Content $mfOriginal -Raw } else { $null }
}

AfterAll {
    if ($script:TempBase -and (Test-Path $script:TempBase)) {
        Remove-Item $script:TempBase -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Restore original PlasterManifest.xml rather than leaving it deleted
    $mf = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
    if ($null -ne $script:OriginalManifestContent) {
        Set-Content -Path $mf -Value $script:OriginalManifestContent -NoNewline
    } elseif (Test-Path $mf) {
        Remove-Item $mf -Force -ErrorAction SilentlyContinue
    }
}


# =============================================================================
# BASIC TEMPLATE
# =============================================================================
Describe 'Basic template — generated module structure' -Skip:(-not $plasterAvailable) {

    BeforeAll {
        $modName = 'PSNowIntegBasic'
        $outDir  = Join-Path $script:TempBase 'Basic'
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null

        Copy-Item (Join-Path $script:PSNowRoot 'PlasterTemplate' 'Basic.xml') `
                  (Join-Path $script:PSNowRoot 'plasterManifest.xml') -Force

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
        $mfLegacy = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
        if (Test-Path $mfLegacy) { Remove-Item $mfLegacy -Force -ErrorAction SilentlyContinue }
        $mf = Join-Path $script:PSNowRoot 'plasterManifest.xml'
        if (Test-Path $mf) { Remove-Item $mf -Force -ErrorAction SilentlyContinue }
    }

    Context 'Core module files' {
        It 'Creates <name>.psd1'                        { (Join-Path $modRoot "$modName.psd1")          | Should -Exist }
        It 'Creates <name>.psm1'                        { (Join-Path $modRoot "$modName.psm1")          | Should -Exist }
        It 'Creates Public\<name>.ps1 starter function' { (Join-Path $modRoot 'Public' "$modName.ps1")    | Should -Exist }
        It 'Creates LICENSE.md'                         { (Join-Path $modRoot 'LICENSE.md')             | Should -Exist }
        It 'Creates README.md'                          { (Join-Path $modRoot 'README.md')              | Should -Exist }
        It 'Creates .gitignore'                         { (Join-Path $modRoot '.gitignore')             | Should -Exist }
    }

    Context 'Module folders' {
        It 'Creates Public folder'        { (Join-Path $modRoot 'Public')        | Should -Exist }
        It 'Creates Private folder'       { (Join-Path $modRoot 'Private')       | Should -Exist }
        It 'Creates Documentation folder' { (Join-Path $modRoot 'Documentation') | Should -Exist }
    }

    Context 'Module manifest validity' {
        BeforeAll {
            $manifest = Test-ModuleManifest -Path (Join-Path $modRoot "$modName.psd1") -ErrorAction SilentlyContinue
        }
        It 'Manifest passes Test-ModuleManifest'        { { Test-ModuleManifest -Path (Join-Path $modRoot "$modName.psd1") -ErrorAction Stop } | Should -Not -Throw }
        It 'Manifest name matches the requested name'   { $manifest.Name       | Should -Be $modName }
        It 'Manifest version matches the requested version' { $manifest.Version | Should -Be '0.1.0' }
        It 'Manifest RootModule references the psm1'   { $manifest.RootModule | Should -Be "$modName.psm1" }
    }

    Context 'AI scaffolding' {
        It 'Creates .github folder'                     { (Join-Path $modRoot '.github')                         | Should -Exist }
        It 'Creates .github\copilot-instructions.md'    { (Join-Path $modRoot '.github' 'copilot-instructions.md') | Should -Exist }
        It 'copilot-instructions.md contains the module name' {
            Get-Content (Join-Path $modRoot '.github' 'copilot-instructions.md') -Raw | Should -Match $modName
        }
    }

    Context 'Community health files' {
        It 'Creates CHANGELOG.md'        { (Join-Path $modRoot 'CHANGELOG.md') | Should -Exist }
        It 'Creates SECURITY.md'         { (Join-Path $modRoot 'SECURITY.md')  | Should -Exist }
        It 'Creates .editorconfig'       { (Join-Path $modRoot '.editorconfig') | Should -Exist }
        It 'Creates .github\ISSUE_TEMPLATE\bug_report.md'     { (Join-Path $modRoot '.github' 'ISSUE_TEMPLATE' 'bug_report.md')     | Should -Exist }
        It 'Creates .github\ISSUE_TEMPLATE\feature_request.md'{ (Join-Path $modRoot '.github' 'ISSUE_TEMPLATE' 'feature_request.md') | Should -Exist }
        It 'Creates .github\pull_request_template.md'          { (Join-Path $modRoot '.github' 'pull_request_template.md')           | Should -Exist }
    }

    Context 'Manifest PS Gallery metadata' {
        It 'LicenseUri is set in the manifest' {
            $psd1 = Get-Content (Join-Path $modRoot "$modName.psd1") -Raw
            $psd1 | Should -Match "LicenseUri\s*=\s*'https://github.com/testuser/testrepo"
        }
        It 'ProjectUri is set in the manifest' {
            $psd1 = Get-Content (Join-Path $modRoot "$modName.psd1") -Raw
            $psd1 | Should -Match "ProjectUri\s*=\s*'https://github.com/testuser/testrepo"
        }
    }

    Context 'Template substitution' {
        It 'Starter function contains the module name' {
            Get-Content (Join-Path $modRoot 'Public' "$modName.ps1") -Raw | Should -Match $modName
        }
        It 'psm1 is parseable PowerShell' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content (Join-Path $modRoot "$modName.psm1")), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context 'Does not include Extended/Advanced-only files' {
        It 'No Build folder'   { (Join-Path $modRoot 'Build')    | Should -Not -Exist }
        It 'No Tests folder'   { (Join-Path $modRoot 'Tests')    | Should -Not -Exist }
        It 'No Spec folder'    { (Join-Path $modRoot 'Spec')     | Should -Not -Exist }
        It 'No Help folder'    { (Join-Path $modRoot 'Help')     | Should -Not -Exist }
        It 'No AGENTS.md'      { (Join-Path $modRoot 'AGENTS.md') | Should -Not -Exist }
        It 'No CLAUDE.md'      { (Join-Path $modRoot 'CLAUDE.md') | Should -Not -Exist }
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

        Copy-Item (Join-Path $script:PSNowRoot 'PlasterTemplate' 'Extended.xml') `
                  (Join-Path $script:PSNowRoot 'plasterManifest.xml') -Force

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
            -FunctionFolders   @('Public','Internal','Classes','Private','Binaries') `
            -Force -NoLogo -ErrorAction Stop

        $modRoot = Join-Path $outDir $modName
    }

    AfterAll {
        $mfLegacy = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
        if (Test-Path $mfLegacy) { Remove-Item $mfLegacy -Force -ErrorAction SilentlyContinue }
        $mf = Join-Path $script:PSNowRoot 'plasterManifest.xml'
        if (Test-Path $mf) { Remove-Item $mf -Force -ErrorAction SilentlyContinue }
    }

    Context 'Core module files' {
        It 'Creates <name>.psd1'                        { (Join-Path $modRoot "$modName.psd1")       | Should -Exist }
        It 'Creates <name>.psm1'                        { (Join-Path $modRoot "$modName.psm1")       | Should -Exist }
        It 'Creates <name>.nuspec'                      { (Join-Path $modRoot "$modName.nuspec")     | Should -Exist }
        It 'Creates Public\<name>.ps1 starter function' { (Join-Path $modRoot 'Public' "$modName.ps1") | Should -Exist }
        It 'Creates LICENSE.md'                         { (Join-Path $modRoot 'LICENSE.md')          | Should -Exist }
        It 'Creates README.md'                          { (Join-Path $modRoot 'README.md')           | Should -Exist }
        It 'Creates .gitignore'                         { (Join-Path $modRoot '.gitignore')          | Should -Exist }
    }

    Context 'Module folders' {
        It 'Creates Public folder'        { (Join-Path $modRoot 'Public')        | Should -Exist }
        It 'Creates Private folder'       { (Join-Path $modRoot 'Private')       | Should -Exist }
        It 'Creates Internal folder'      { (Join-Path $modRoot 'Internal')      | Should -Exist }
        It 'Creates Classes folder'       { (Join-Path $modRoot 'Classes')       | Should -Exist }
        It 'Creates Binaries folder'      { (Join-Path $modRoot 'Binaries')      | Should -Exist }
        It 'Creates Documentation folder' { (Join-Path $modRoot 'Documentation') | Should -Exist }
        It 'Creates Certs folder'         { (Join-Path $modRoot 'Certs')         | Should -Exist }
    }

    Context 'Module manifest validity' {
        BeforeAll {
            $manifest = Test-ModuleManifest -Path (Join-Path $modRoot "$modName.psd1") -ErrorAction SilentlyContinue
        }
        It 'Manifest passes Test-ModuleManifest'            { { Test-ModuleManifest -Path (Join-Path $modRoot "$modName.psd1") -ErrorAction Stop } | Should -Not -Throw }
        It 'Manifest name matches the requested name'       { $manifest.Name       | Should -Be $modName }
        It 'Manifest version matches the requested version' { $manifest.Version    | Should -Be '0.1.0' }
        It 'Manifest RootModule references the psm1'        { $manifest.RootModule | Should -Be "$modName.psm1" }
    }

    Context 'VS Code support' {
        It 'Creates .vscode folder'        { (Join-Path $modRoot '.vscode')              | Should -Exist }
        It 'Creates .vscode\settings.json' { (Join-Path $modRoot '.vscode' 'settings.json') | Should -Exist }
        It 'Creates .vscode\task.json'     { (Join-Path $modRoot '.vscode' 'task.json')     | Should -Exist }
    }

    Context 'Build tooling' {
        It 'Creates Build folder'                        { (Join-Path $modRoot 'Build')                               | Should -Exist }
        It 'Creates Build\build.ps1'                     { (Join-Path $modRoot 'Build' 'build.ps1')                     | Should -Exist }
        It 'Creates Build\build.depend.psd1'             { (Join-Path $modRoot 'Build' 'build.depend.psd1')             | Should -Exist }
        It 'Creates Build\build.psake.ps1'               { (Join-Path $modRoot 'Build' 'build.psake.ps1')               | Should -Exist }
        It 'Creates Build\deploy.psdeploy.ps1'           { (Join-Path $modRoot 'Build' 'deploy.psdeploy.ps1')           | Should -Exist }
        It 'Creates Build\PSScriptAnalyzerSettings.psd1' { (Join-Path $modRoot 'Build' 'PSScriptAnalyzerSettings.psd1') | Should -Exist }
    }

    Context 'Pester test structure' {
        It 'Creates Tests folder'                         { (Join-Path $modRoot 'Tests')                              | Should -Exist }
        It 'Creates Tests\Unit folder'                    { (Join-Path $modRoot 'Tests' 'Unit')                         | Should -Exist }
        It 'Creates Tests\Common folder'                  { (Join-Path $modRoot 'Tests' 'Common')                       | Should -Exist }
        It 'Creates Tests\Unit\Unit.Tests.ps1'            { (Join-Path $modRoot 'Tests' 'Unit' 'Unit.Tests.ps1')           | Should -Exist }
        It 'Creates Tests\Common\Basic.tests.ps1'         { (Join-Path $modRoot 'Tests' 'Common' 'Basic.tests.ps1')        | Should -Exist }
        It 'Creates Tests\Common\Environment.tests.ps1'   { (Join-Path $modRoot 'Tests' 'Common' 'Environment.tests.ps1')  | Should -Exist }
        It 'Creates Tests\Common\Help.Tests.ps1'          { (Join-Path $modRoot 'Tests' 'Common' 'Help.Tests.ps1')         | Should -Exist }
        It 'Creates Tests\Common\Manifest.Tests.ps1'      { (Join-Path $modRoot 'Tests' 'Common' 'Manifest.Tests.ps1')     | Should -Exist }
    }

    Context 'AI scaffolding' {
        It 'Creates .github folder'                  { (Join-Path $modRoot '.github')                         | Should -Exist }
        It 'Creates .github\copilot-instructions.md' { (Join-Path $modRoot '.github' 'copilot-instructions.md') | Should -Exist }
        It 'Creates AGENTS.md'                       { (Join-Path $modRoot 'AGENTS.md')                       | Should -Exist }
        It 'copilot-instructions.md contains the module name' {
            Get-Content (Join-Path $modRoot '.github' 'copilot-instructions.md') -Raw | Should -Match $modName
        }
        It 'AGENTS.md contains the module name' {
            Get-Content (Join-Path $modRoot 'AGENTS.md') -Raw | Should -Match $modName
        }
    }

    Context 'Community health files' {
        It 'Creates CHANGELOG.md'        { (Join-Path $modRoot 'CHANGELOG.md')   | Should -Exist }
        It 'Creates CONTRIBUTING.md'     { (Join-Path $modRoot 'CONTRIBUTING.md') | Should -Exist }
        It 'Creates SECURITY.md'         { (Join-Path $modRoot 'SECURITY.md')    | Should -Exist }
        It 'Creates .editorconfig'       { (Join-Path $modRoot '.editorconfig')   | Should -Exist }
        It 'Creates .github\ISSUE_TEMPLATE\bug_report.md'     { (Join-Path $modRoot '.github' 'ISSUE_TEMPLATE' 'bug_report.md')     | Should -Exist }
        It 'Creates .github\ISSUE_TEMPLATE\feature_request.md'{ (Join-Path $modRoot '.github' 'ISSUE_TEMPLATE' 'feature_request.md') | Should -Exist }
        It 'Creates .github\pull_request_template.md'          { (Join-Path $modRoot '.github' 'pull_request_template.md')           | Should -Exist }
        It 'Creates .github\workflows\ci.yml'                  { (Join-Path $modRoot '.github' 'workflows' 'ci.yml')                 | Should -Exist }
    }

    Context 'Manifest PS Gallery metadata' {
        It 'LicenseUri is set in the manifest' {
            $psd1 = Get-Content (Join-Path $modRoot "$modName.psd1") -Raw
            $psd1 | Should -Match "LicenseUri\s*=\s*'https://github.com/testuser/testrepo"
        }
        It 'ProjectUri is set in the manifest' {
            $psd1 = Get-Content (Join-Path $modRoot "$modName.psd1") -Raw
            $psd1 | Should -Match "ProjectUri\s*=\s*'https://github.com/testuser/testrepo"
        }
    }

    Context 'Template substitution' {
        It 'nuspec contains the module name' {
            Get-Content (Join-Path $modRoot "$modName.nuspec") -Raw | Should -Match $modName
        }
        It 'build.psake.ps1 is parseable PowerShell' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content (Join-Path $modRoot 'Build' 'build.psake.ps1')), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context 'Does not include Advanced-only files' {
        It 'No CLAUDE.md'   { (Join-Path $modRoot 'CLAUDE.md') | Should -Not -Exist }
        It 'No Spec folder' { (Join-Path $modRoot 'Spec')      | Should -Not -Exist }
        It 'No Help folder' { (Join-Path $modRoot 'Help')      | Should -Not -Exist }
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

        Copy-Item (Join-Path $script:PSNowRoot 'PlasterTemplate' 'Advanced.xml') `
                  (Join-Path $script:PSNowRoot 'plasterManifest.xml') -Force

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
            -FunctionFolders   @('Public','Internal','Classes','Private','Binaries','DSCResources') `
            -Options           'All' `
            -Force -NoLogo -ErrorAction Stop

        $modRoot = Join-Path $outDir $modName
    }

    AfterAll {
        $mfLegacy = Join-Path $script:PSNowRoot 'PlasterManifest.xml'
        if (Test-Path $mfLegacy) { Remove-Item $mfLegacy -Force -ErrorAction SilentlyContinue }
        $mf = Join-Path $script:PSNowRoot 'plasterManifest.xml'
        if (Test-Path $mf) { Remove-Item $mf -Force -ErrorAction SilentlyContinue }
    }

    Context 'Core module files' {
        It 'Creates <name>.psd1'                        { (Join-Path $modRoot "$modName.psd1")       | Should -Exist }
        It 'Creates <name>.psm1'                        { (Join-Path $modRoot "$modName.psm1")       | Should -Exist }
        It 'Creates <name>.nuspec'                      { (Join-Path $modRoot "$modName.nuspec")     | Should -Exist }
        It 'Creates Public\<name>.ps1 starter function' { (Join-Path $modRoot 'Public' "$modName.ps1") | Should -Exist }
        It 'Creates LICENSE.md'                         { (Join-Path $modRoot 'LICENSE.md')          | Should -Exist }
        # Advanced.xml uses 'Readme.md' (mixed case) — intentional difference from Basic/Extended
        It 'Creates Readme.md'                          { (Join-Path $modRoot 'Readme.md')           | Should -Exist }
        It 'Creates .gitignore (Options includes Git)'  { (Join-Path $modRoot '.gitignore')          | Should -Exist }
    }

    Context 'Module folders' {
        It 'Creates Public folder'        { (Join-Path $modRoot 'Public')        | Should -Exist }
        It 'Creates Private folder'       { (Join-Path $modRoot 'Private')       | Should -Exist }
        It 'Creates Internal folder'      { (Join-Path $modRoot 'Internal')      | Should -Exist }
        It 'Creates Classes folder'       { (Join-Path $modRoot 'Classes')       | Should -Exist }
        It 'Creates Binaries folder'      { (Join-Path $modRoot 'Binaries')      | Should -Exist }
        It 'Creates DSCResources folder'  { (Join-Path $modRoot 'DSCResources')  | Should -Exist }
        It 'Creates Documentation folder' { (Join-Path $modRoot 'Documentation') | Should -Exist }
    }

    Context 'Module manifest validity' {
        BeforeAll {
            $manifest = Test-ModuleManifest -Path (Join-Path $modRoot "$modName.psd1") -ErrorAction SilentlyContinue
        }
        It 'Manifest passes Test-ModuleManifest'            { { Test-ModuleManifest -Path (Join-Path $modRoot "$modName.psd1") -ErrorAction Stop } | Should -Not -Throw }
        It 'Manifest name matches the requested name'       { $manifest.Name       | Should -Be $modName }
        It 'Manifest version matches the requested version' { $manifest.Version    | Should -Be '0.1.0' }
        It 'Manifest RootModule references the psm1'        { $manifest.RootModule | Should -Be "$modName.psm1" }
    }

    Context 'Spec (Gherkin) folder — unconditional in Advanced' {
        It 'Creates Spec folder'             { (Join-Path $modRoot 'Spec')                        | Should -Exist }
        It 'Creates Spec\<name>.feature'     { (Join-Path $modRoot 'Spec' "$modName.feature")       | Should -Exist }
        It 'Creates Spec\<name>.Steps.ps1'   { (Join-Path $modRoot 'Spec' "$modName.Steps.ps1")     | Should -Exist }
    }

    Context 'VS Code support' {
        It 'Creates .vscode folder'        { (Join-Path $modRoot '.vscode')               | Should -Exist }
        It 'Creates .vscode\settings.json' { (Join-Path $modRoot '.vscode' 'settings.json')  | Should -Exist }
        It 'Creates .vscode\task.json'     { (Join-Path $modRoot '.vscode' 'task.json')      | Should -Exist }
    }

    Context 'Build tooling (Options includes psake)' {
        It 'Creates Build folder'                        { (Join-Path $modRoot 'Build')                               | Should -Exist }
        It 'Creates Build\build.ps1'                     { (Join-Path $modRoot 'Build' 'build.ps1')                     | Should -Exist }
        It 'Creates Build\build.depend.psd1'             { (Join-Path $modRoot 'Build' 'build.depend.psd1')             | Should -Exist }
        It 'Creates Build\build.psake.ps1'               { (Join-Path $modRoot 'Build' 'build.psake.ps1')               | Should -Exist }
        It 'Creates Build\deploy.psdeploy.ps1'           { (Join-Path $modRoot 'Build' 'deploy.psdeploy.ps1')           | Should -Exist }
        It 'Creates Certs folder'                        { (Join-Path $modRoot 'Certs')                               | Should -Exist }
        It 'Creates Certs\openssl.cfg'                   { (Join-Path $modRoot 'Certs' 'openssl.cfg')                   | Should -Exist }
    }

    Context 'Script analysis support (Options includes PSScriptAnalyzer)' {
        It 'Creates Build\PSScriptAnalyzerSettings.psd1' { (Join-Path $modRoot 'Build' 'PSScriptAnalyzerSettings.psd1') | Should -Exist }
    }

    Context 'Pester test structure (Options includes Pester)' {
        It 'Creates Tests folder'                            { (Join-Path $modRoot 'Tests')                                   | Should -Exist }
        It 'Creates Tests\Unit folder'                       { (Join-Path $modRoot 'Tests' 'Unit')                              | Should -Exist }
        It 'Creates Tests\Common folder'                     { (Join-Path $modRoot 'Tests' 'Common')                            | Should -Exist }
        It 'Creates Tests\Acceptance folder'                 { (Join-Path $modRoot 'Tests' 'Acceptance')                        | Should -Exist }
        It 'Creates Tests\Unit\Unit.Tests.ps1'               { (Join-Path $modRoot 'Tests' 'Unit' 'Unit.Tests.ps1')                | Should -Exist }
        It 'Creates Tests\Common\Basic.tests.ps1'            { (Join-Path $modRoot 'Tests' 'Common' 'Basic.tests.ps1')             | Should -Exist }
        It 'Creates Tests\Common\Environment.tests.ps1'      { (Join-Path $modRoot 'Tests' 'Common' 'Environment.tests.ps1')       | Should -Exist }
        It 'Creates Tests\Common\Help.Tests.ps1'             { (Join-Path $modRoot 'Tests' 'Common' 'Help.Tests.ps1')              | Should -Exist }
        It 'Creates Tests\Common\Manifest.Tests.ps1'         { (Join-Path $modRoot 'Tests' 'Common' 'Manifest.Tests.ps1')          | Should -Exist }
        It 'Creates Tests\Common\PSSA.Tests.wip.ps1'         { (Join-Path $modRoot 'Tests' 'Common' 'PSSA.Tests.wip.ps1')          | Should -Exist }
        It 'Creates Tests\Common\Analyzer.tests.ps1.example' { (Join-Path $modRoot 'Tests' 'Common' 'Analyzer.tests.ps1.example')  | Should -Exist }
        It 'Creates Tests\Acceptance\Project.Tests.ps1'      { (Join-Path $modRoot 'Tests' 'Acceptance' 'Project.Tests.ps1')       | Should -Exist }
    }

    Context 'PlatyPS help support (Options includes platyPS)' {
        It 'Creates Help folder'                     { (Join-Path $modRoot 'Help')                              | Should -Exist }
        It "Creates Help\about_<name>.help.md"       { (Join-Path $modRoot 'Help' "about_$modName.help.md")       | Should -Exist }
    }

    Context 'AI scaffolding' {
        It 'Creates .github folder'                  { (Join-Path $modRoot '.github')                         | Should -Exist }
        It 'Creates .github\copilot-instructions.md' { (Join-Path $modRoot '.github' 'copilot-instructions.md') | Should -Exist }
        It 'Creates AGENTS.md'                       { (Join-Path $modRoot 'AGENTS.md')                       | Should -Exist }
        It 'Creates CLAUDE.md'                       { (Join-Path $modRoot 'CLAUDE.md')                       | Should -Exist }
        It 'copilot-instructions.md contains the module name' {
            Get-Content (Join-Path $modRoot '.github' 'copilot-instructions.md') -Raw | Should -Match $modName
        }
        It 'AGENTS.md contains the module name' {
            Get-Content (Join-Path $modRoot 'AGENTS.md') -Raw | Should -Match $modName
        }
        It 'CLAUDE.md contains the module name' {
            Get-Content (Join-Path $modRoot 'CLAUDE.md') -Raw | Should -Match $modName
        }
    }

    Context 'Community health files' {
        It 'Creates CHANGELOG.md'        { (Join-Path $modRoot 'CHANGELOG.md')   | Should -Exist }
        It 'Creates CONTRIBUTING.md'     { (Join-Path $modRoot 'CONTRIBUTING.md') | Should -Exist }
        It 'Creates SECURITY.md'         { (Join-Path $modRoot 'SECURITY.md')    | Should -Exist }
        It 'Creates .editorconfig'       { (Join-Path $modRoot '.editorconfig')   | Should -Exist }
        It 'Creates .github\ISSUE_TEMPLATE\bug_report.md'     { (Join-Path $modRoot '.github' 'ISSUE_TEMPLATE' 'bug_report.md')     | Should -Exist }
        It 'Creates .github\ISSUE_TEMPLATE\feature_request.md'{ (Join-Path $modRoot '.github' 'ISSUE_TEMPLATE' 'feature_request.md') | Should -Exist }
        It 'Creates .github\pull_request_template.md'          { (Join-Path $modRoot '.github' 'pull_request_template.md')           | Should -Exist }
        It 'Creates .github\workflows\ci.yml'                  { (Join-Path $modRoot '.github' 'workflows' 'ci.yml')                 | Should -Exist }
    }

    Context 'Manifest PS Gallery metadata' {
        It 'LicenseUri is set in the manifest' {
            $psd1 = Get-Content (Join-Path $modRoot "$modName.psd1") -Raw
            $psd1 | Should -Match "LicenseUri\s*=\s*'https://github.com/testuser/testrepo"
        }
        It 'ProjectUri is set in the manifest' {
            $psd1 = Get-Content (Join-Path $modRoot "$modName.psd1") -Raw
            $psd1 | Should -Match "ProjectUri\s*=\s*'https://github.com/testuser/testrepo"
        }
    }

    Context 'Template substitution' {
        It 'nuspec contains the module name' {
            Get-Content (Join-Path $modRoot "$modName.nuspec") -Raw | Should -Match $modName
        }
        It 'build.psake.ps1 is parseable PowerShell' {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content (Join-Path $modRoot 'Build' 'build.psake.ps1')), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
}
