[CmdletBinding()]
param(
    [string]$InputFile = "./ai-track-docs/architecture.mmd",
    [string]$OutputFile = "./BuildOutput/architecture.svg"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $InputFile -PathType Leaf)) {
    throw "Architecture diagram source not found: $InputFile"
}

$outputDirectory = Split-Path -Path $OutputFile -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDirectory) -and -not (Test-Path -Path $outputDirectory -PathType Container)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
}

Write-Output "[validate-architecture] Rendering Mermaid diagram from $InputFile"

# npx installs and runs a pinned Mermaid CLI without requiring a committed package.json.
# Pinning avoids engine mismatches on older Node runtimes used in some local environments.
$arguments = @(
    '--yes'
    '@mermaid-js/mermaid-cli@10.9.1'
    '-i', $InputFile
    '-o', $OutputFile
)

npx @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Mermaid diagram render failed."
}

if (-not (Test-Path -Path $OutputFile -PathType Leaf)) {
    throw "Mermaid CLI completed but output file was not created: $OutputFile"
}

Write-Output "[validate-architecture] Render successful: $OutputFile"
