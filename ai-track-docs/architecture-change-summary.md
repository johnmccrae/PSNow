# Architecture Diagram Change Summary

## What Changed

Three private helper functions existed in `Private/` but were absent from the architecture diagram.
This PR adds them to both `architecture.mmd` (Mermaid source) and `architecture.md` (prose map).

| Helper | File | Consumed by |
|---|---|---|
| `Remove-OldPSNowManifest` | `Private/Remove-OldPSNowManifest.ps1` | `New-PSNowModule` — removes stale `PlasterManifest.xml` and copies the selected template before calling `Invoke-Plaster` |
| `Write-PSNowStructuredLog` | `Private/Write-PSNowStructuredLog.ps1` | `New-PSNowModule` — emits structured `op=… status=… key=value` log lines via `Write-Verbose` |
| `Write-PSNowScriptNoWhitespace` | `Private/Write-PSNowScriptNoWhitespace.ps1` | Standalone developer utility — trims trailing whitespace from all `.ps1`/`.psm1`/`.psd1` files |

## Before State

The before state of `architecture.mmd` is preserved at `ai-track-docs/architecture-before.mmd`.

Nodes that existed:
- `EnvHelpers` (Get-PSNowEnvironmentVariables)
- `NewCmd`, `FindCmd` (public commands)
- `Templates`, `ModuleTracker`
- Build/CI nodes: `PsakeTasks`, `ValidationScript`, `Pipeline`, `ArchDiagram`, `RenderedDiagram`

## After State

Three nodes added:
- `ManifestHelper` → `Private/Remove-OldPSNowManifest.ps1`
- `LogHelper` → `Private/Write-PSNowStructuredLog.ps1`
- `WhitespaceHelper` → `Private/Write-PSNowScriptNoWhitespace.ps1`

Two new edges added from `NewCmd`:
- `NewCmd --> ManifestHelper`
- `NewCmd -->|logs via| LogHelper`

## Repeatable Refresh Process

Run `scripts/Update-ArchitectureDiagram.ps1` at any time to regenerate the diagram from the live codebase:

```powershell
# Regenerate only
./scripts/Update-ArchitectureDiagram.ps1

# Regenerate and render SVG (requires Node.js + npx)
./scripts/Update-ArchitectureDiagram.ps1 -Render
```

The script:
1. Scans `Public/` and `Private/` for `.ps1` files.
2. Reads `PlasterTemplate/` for `.xml` manifests.
3. Rebuilds `ai-track-docs/architecture.mmd`.
4. Prints a summary of added/removed nodes.
5. Optionally calls `scripts/validate-architecture.ps1` to produce `BuildOutput/architecture.svg`.

## Rollback Guidance

To revert the diagram to its pre-PR state:

```powershell
# Option 1 — restore from the captured before file
Copy-Item ai-track-docs/architecture-before.mmd ai-track-docs/architecture.mmd

# Option 2 — revert via git
git revert <this-commit-sha>
```

The `architecture-before.mmd` file is kept in the repo as an explicit rollback artifact for this exercise.
Remove it once you are satisfied that the updated diagram is stable.
