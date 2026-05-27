<#
.SYNOPSIS
    Regenerates ai-track-docs/architecture.mmd from the live codebase and optionally renders it to SVG.

.DESCRIPTION
    Scans Public/ and Private/ for .ps1 files, reads PlasterTemplate/ for .xml manifests,
    and rebuilds architecture.mmd to reflect the current structure.
    If the diagram changed, prints a summary of what was added or removed.
    Pass -Render to also produce BuildOutput/architecture.svg via the Mermaid CLI.

.PARAMETER RepoRoot
    Root of the PSNow repository. Defaults to the parent of the scripts/ folder.

.PARAMETER Render
    When specified, calls scripts/validate-architecture.ps1 to render the SVG.

.EXAMPLE
    ./scripts/Update-ArchitectureDiagram.ps1
    ./scripts/Update-ArchitectureDiagram.ps1 -Render
#>
[CmdletBinding()]
param (
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$Render
)

$ErrorActionPreference = 'Stop'

$DiagramPath = Join-Path $RepoRoot 'ai-track-docs\architecture.mmd'

# ── Discover live components ─────────────────────────────────────────────────

$publicFiles   = Get-ChildItem (Join-Path $RepoRoot 'Public')          -Filter '*.ps1' | Sort-Object Name
$privateFiles  = Get-ChildItem (Join-Path $RepoRoot 'Private')         -Filter '*.ps1' | Sort-Object Name
$templateFiles = Get-ChildItem (Join-Path $RepoRoot 'PlasterTemplate') -Filter '*.xml' | Sort-Object Name

# Build a safe Mermaid node-id from a file stem (strip hyphens/dots)
function Get-NodeId([string]$stem) { $stem -replace '[^A-Za-z0-9]', '' }

# ── Build node declarations ───────────────────────────────────────────────────

$publicNodes  = $publicFiles  | ForEach-Object {
    $id    = Get-NodeId $_.BaseName
    $label = $_.BaseName + '\npath: Public/' + $_.Name
    "    ${id}[${label}]"
}

$privateNodes = $privateFiles | ForEach-Object {
    $id    = Get-NodeId $_.BaseName
    $label = $_.BaseName + '\npath: Private/' + $_.Name
    "    ${id}[${label}]"
}

$templateList = ($templateFiles | ForEach-Object { 'PlasterTemplate/' + $_.Name }) -join '\n'
$templateNode = "    Templates[Plaster templates\npath: $templateList]"

# ── Build edges ───────────────────────────────────────────────────────────────

$moduleEntryToPublic = $publicFiles | ForEach-Object {
    "    ModuleEntry --> $(Get-NodeId $_.BaseName)"
}

# Generic: every private helper is reachable from the module entry
$privateEdges = $privateFiles | ForEach-Object {
    "    ModuleEntry --> $(Get-NodeId $_.BaseName)"
}

# ── Compose full diagram ──────────────────────────────────────────────────────

$lines = @(
    'flowchart TD'
    '    %% Entry points'
    '    User[User or CI]'
    '    ModuleEntry[PSNow.psm1\npath: PSNow.psm1]'
    '    BuildEntry[Build entry\npath: Build/build.ps1]'
    '    ValidateScript[Architecture validation\npath: scripts/validate-architecture.ps1]'
    ''
    '    %% Public commands'
)
$lines += $publicNodes
$lines += ''
$lines += '    %% Private helpers'
$lines += $privateNodes
$lines += ''
$lines += '    %% Build and verification'
$lines += @(
    '    PsakeTasks[PSake tasks\npath: Build/build.psake.ps1]'
    '    ValidationScript[General validation\npath: scripts/validate.ps1]'
    '    Pipeline[Azure pipeline\npath: azure-pipelines.yml]'
    '    ArchDiagram[Architecture diagram source\npath: ai-track-docs/architecture.mmd]'
    '    RenderedDiagram[Rendered diagram artifact\npath: BuildOutput/architecture.svg]'
    $templateNode
    '    ModuleTracker[currentmodules.txt\npath: currentmodules.txt]'
    ''
    '    %% Module import edges'
    '    User --> ModuleEntry'
)
$lines += $moduleEntryToPublic
$lines += $privateEdges
$lines += @(
    ''
    '    %% Public command data flow'
    '    NewPSNowModule -->|writes generated scaffold| GeneratedModule[Generated module files\npath: <ModuleRoot>/<NewModuleName>/...]'
    '    NewPSNowModule -->|appends module path| ModuleTracker'
    '    FindPSNowModule -->|reads module list| ModuleTracker'
    '    NewPSNowModule --> Templates'
    ''
    '    %% Build and CI dependency flow'
    '    User --> BuildEntry'
    '    BuildEntry --> PsakeTasks'
    '    ValidationScript --> BuildEntry'
    '    Pipeline --> BuildEntry'
    ''
    '    %% Diagram validation flow'
    '    User --> ValidateScript'
    '    Pipeline --> ValidateScript'
    '    ValidateScript --> ArchDiagram'
    '    ValidateScript -->|renders to verify syntax and layout| RenderedDiagram'
)

$newContent = $lines -join "`n"

# ── Compare and report changes ────────────────────────────────────────────────

$oldContent = if (Test-Path $DiagramPath) { Get-Content $DiagramPath -Raw } else { '' }

if ($oldContent.TrimEnd() -eq $newContent.TrimEnd()) {
    Write-Output "[Update-ArchitectureDiagram] No changes detected — diagram is up to date."
}
else {
    # Summarise which node labels appeared / disappeared
    $oldNodes = [regex]::Matches($oldContent, '\[([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value }
    $newNodes = [regex]::Matches($newContent, '\[([^\]]+)\]') | ForEach-Object { $_.Groups[1].Value }

    $added   = $newNodes | Where-Object { $_ -notin $oldNodes }
    $removed = $oldNodes | Where-Object { $_ -notin $newNodes }

    if ($added)   { Write-Output "[Update-ArchitectureDiagram] Nodes added:`n  $($added   -join "`n  ")" }
    if ($removed) { Write-Output "[Update-ArchitectureDiagram] Nodes removed:`n  $($removed -join "`n  ")" }

    Set-Content -Path $DiagramPath -Value $newContent -Encoding UTF8
    Write-Output "[Update-ArchitectureDiagram] Diagram written to $DiagramPath"
}

# ── Optional render ───────────────────────────────────────────────────────────

if ($Render) {
    $validateScript = Join-Path $RepoRoot 'scripts\validate-architecture.ps1'
    Write-Output "[Update-ArchitectureDiagram] Rendering SVG..."
    & $validateScript -InputFile $DiagramPath -OutputFile (Join-Path $RepoRoot 'BuildOutput\architecture.svg')
}
