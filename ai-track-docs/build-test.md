# Build and Test

Run commands from the repository root.

## First-time setup
```powershell
./Build/Build.ps1 -ResolveDependency
```

## Build environment
```powershell
./Build/Build.ps1 -TaskList init
```

## Test
```powershell
./Build/Build.ps1 -TaskList test
```

## Lint (PSScriptAnalyzer)
```powershell
./Build/Build.ps1 -TaskList analyze
```

## Lint + test
```powershell
./Build/Build.ps1 -TaskList analyze,test
```

## Stage output
```powershell
./Build/Build.ps1 -TaskList stage
```

This is a starter reference and will be refined in Exercise 2.
