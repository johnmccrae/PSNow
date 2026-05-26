## Summary
- What changed and why
- Plan: <!-- link to plan or inline summary -->
- Files/paths touched:

## Evidence
- Tests/logs: <!-- commands + output summary -->
- Coverage: <!-- percentage or contract evidence -->

## Risk & Rollback
- Risk: low / medium / high
- Rollback: `revert <commit SHA>` or toggle `<flag>`

## Review Focus
<!-- 3-5 bullets — what to look at and why -->
- 
- 
- 

## Verification Steps
<!-- Steps the reviewer can run locally to confirm the change works -->
```powershell
# 1. Stage the module
.\Build\build.ps1 -TaskList Stage

# 2. Run the tests
.\Build\build.ps1 -TaskList Test

# 3. <add scenario-specific steps here>
```

## Track
- Level: <!-- Walk / Run / Fly -->
- Exercise: <!-- ex# -->
