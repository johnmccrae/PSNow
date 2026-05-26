#Requires -Version 5.1
<#
.SYNOPSIS
    Contract tests for the three Plaster template manifests (Basic, Extended, Advanced).

.DESCRIPTION
    These tests guard the parameter interface between New-PSNowModule and the Plaster
    XML manifests it invokes.  New-PSNowModule always forwards the keys listed in
    $RequiredParameters when it calls Invoke-Plaster; every manifest must declare
    exactly those parameter names or the invocation will fail at runtime.

    Contract surface: PlasterTemplate/<name>.xml
    Consumer:         Public/New-PSNowModule.ps1  ($PlasterParams hashtable)

.NOTES
    HOW TO UPDATE THE CONTRACT
    --------------------------
    If you intentionally rename, add, or remove a Plaster parameter:

      1. Edit the relevant manifest XML (PlasterTemplate/<name>.xml) to reflect
         the new parameter name.
      2. Update the $RequiredParameters array in THIS file to match.
      3. Update New-PSNowModule.ps1: rename the corresponding key in $PlasterParams
         so it matches the new parameter name.
      4. Run the contract tests to confirm everything aligns:
             Invoke-Pester -Path .\tests\Unit\PlasterTemplate.Contract.tests.ps1
      5. Commit both the manifest change and the test change together so the contract
         stays in sync.
#>

Set-StrictMode -Version Latest

$repoRoot = if (-not [string]::IsNullOrWhiteSpace($Env:BHProjectPath)) {
    $Env:BHProjectPath
} elseif (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    (Get-Location).Path
}

$templatePath = Join-Path -Path $repoRoot -ChildPath 'PlasterTemplate'

# -------------------------------------------------------------------
# CONTRACT DEFINITION
# -------------------------------------------------------------------
# Parameters that New-PSNowModule unconditionally forwards to Invoke-Plaster
# via the $PlasterParams hashtable.  Every manifest must declare each of these.
$RequiredParameters = @(
    'ModuleName'
    'GitHubUserName'
    'PowerShellVersion'
)

# Required child elements under <metadata> per the Plaster v1 schema.
$RequiredMetadataFields = @(
    'name'
    'id'
    'version'
    'title'
    'description'
    'author'
)

# The three manifests that New-PSNowModule's -BaseManifest parameter accepts.
# Use Pester 5 -ForEach to avoid foreach-closure variable-capture issues.
$ManifestTestCases = @(
    @{ ManifestName = 'Basic';    ManifestPath = Join-Path $templatePath 'Basic.xml' }
    @{ ManifestName = 'Extended'; ManifestPath = Join-Path $templatePath 'Extended.xml' }
    @{ ManifestName = 'Advanced'; ManifestPath = Join-Path $templatePath 'Advanced.xml' }
)

# Build flat test-case arrays for the per-field/per-parameter Its.
$MetadataFieldTestCases = $RequiredMetadataFields | ForEach-Object { @{ FieldName = $_ } }
$ParameterTestCases     = $RequiredParameters     | ForEach-Object { @{ ParamName = $_ } }

Describe 'Plaster Template Manifest Contract' {

    # Each Context runs once per manifest entry in $ManifestTestCases.
    # Within the Context, $ManifestName and $ManifestPath are available as variables.
    Context 'Manifest: <ManifestName>' -ForEach $ManifestTestCases {

        BeforeAll {
            $script:xmlDoc = [xml](Get-Content -Path $ManifestPath -Raw -ErrorAction Stop)
        }

        It 'manifest file exists on disk' {
            Test-Path -Path $ManifestPath | Should -BeTrue
        }

        It 'is well-formed XML' {
            { [xml](Get-Content -Path $ManifestPath -Raw) } | Should -Not -Throw
        }

        It 'has a valid schemaVersion attribute (major.minor)' {
            $script:xmlDoc.plasterManifest.schemaVersion | Should -Match '^\d+\.\d+$'
        }

        It 'root element is plasterManifest' {
            $script:xmlDoc.DocumentElement.LocalName | Should -Be 'plasterManifest'
        }

        # Validate every required metadata field is present and non-empty.
        It "metadata contains a non-empty '<FieldName>' element" -ForEach $MetadataFieldTestCases {
            $value = $script:xmlDoc.plasterManifest.metadata.$FieldName
            $value | Should -Not -BeNullOrEmpty
        }

        # Core parameter contract: each required parameter must be declared.
        It "declares required parameter '<ParamName>'" -ForEach $ParameterTestCases {
            $declared = $script:xmlDoc.plasterManifest.parameters.parameter |
                Where-Object { $_.name -eq $ParamName }
            $declared | Should -Not -BeNullOrEmpty
        }

        It 'has at least one <newModuleManifest> content element' {
            $elements = $script:xmlDoc.plasterManifest.content.newModuleManifest
            $elements | Should -Not -BeNullOrEmpty
        }

        It '<newModuleManifest> destination references PLASTER_PARAM_ModuleName' {
            $dest = $script:xmlDoc.plasterManifest.content.newModuleManifest.destination
            $dest | Should -Match 'PLASTER_PARAM_ModuleName'
        }

        It '<newModuleManifest> rootModule references ModuleName parameter' {
            $rootMod = $script:xmlDoc.plasterManifest.content.newModuleManifest.rootModule
            $rootMod | Should -Match 'PLASTER_PARAM_ModuleName'
        }
    }
}
