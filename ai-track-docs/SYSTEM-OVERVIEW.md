# System Overview

## Purpose
PSNow is a PowerShell scaffolding module that generates new PowerShell module projects from Plaster templates.

## Core Flow
1. Import PSNow.
2. Run `New-PSNowModule`.
3. Select a template (`Basic`, `Extended`, or `Advanced`).
4. PSNow invokes Plaster to scaffold a new module structure.

## Key Areas
- `Public/`: exported functions.
- `Private/`: internal helpers.
- `PlasterTemplate/`: template manifests.
- `Build/`: PSake build and test orchestration.
- `tests/`: unit, integration, and acceptance tests.

## Notes
This file is intentionally lightweight and will be expanded in later exercises.
