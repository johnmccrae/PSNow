# PSNow Feature Flags

PSNow uses environment variables to control optional or evolving behaviour without
requiring code changes. Flags default to **OFF** (opt-in) — new behaviour must be
explicitly enabled, ensuring existing pipelines are unaffected on upgrade.

## Flag Helper

`Get-PSNowFeatureFlag -Name '<FlagName>'`

Reads `$env:PSNOW_<FLAG_NAME_UPPERCASE>` and returns `$true` (enabled) or
`$false` (disabled). Unset or empty = **enabled**.

| Env var value | State |
|---|---|
| *(unset or empty)* | OFF |
| `1`, `true`, `yes` | ON |
| `0`, `false`, `no` | OFF |

Naming convention: PascalCase flag name → `PSNOW_SCREAMING_SNAKE_CASE`
e.g. `StrictLogSanitization` → `PSNOW_STRICT_LOG_SANITIZATION`

---

## PSNOW_STRICT_LOG_SANITIZATION

**File:** `Private/Write-PSNowStructuredLog.ps1`
**Default state:** OFF (opt-in)
**Introduced:** Ex13 / closes Issue #51

### Purpose

`Write-PSNowStructuredLog` emits structured verbose log lines in the format:

```
[op=<operation>, status=<status>, key=value, ...]
```

When a field value contains delimiter characters (`]`, `,`, `=`, or whitespace)
the raw concatenation produces an ambiguous log entry that cannot be reliably
parsed downstream. With this flag **ON**, such values are automatically wrapped
in double quotes:

```
# FLAG OFF — raw (legacy behaviour)
[op=find-modules, status=completed, path=/my path/here]

# FLAG ON — sanitized
[op=find-modules, status=completed, path="/my path/here"]
```

Clean values (no delimiters) are never quoted regardless of flag state.

### Enabling / Disabling

```powershell
# Enable strict sanitization (opt-in)
$env:PSNOW_STRICT_LOG_SANITIZATION = '1'

# Disable / revert to legacy raw concatenation (default when unset)
$env:PSNOW_STRICT_LOG_SANITIZATION = '0'   # or simply remove the env var
```

Set permanently in your PowerShell profile or CI pipeline environment variables.

### Evidence: ON vs OFF

| Flag state | Input value | Emitted log fragment |
|---|---|---|
| OFF | `/path with spaces` | `path=/path with spaces` |
| ON  | `/path with spaces` | `path="/path with spaces"` |
| OFF | `a,b,c` | `tags=a,b,c` |
| ON  | `a,b,c` | `tags="a,b,c"` |
| ON  | `BasicModule` | `manifest=BasicModule` *(no quotes — clean value)* |

### Rollback

Set `$env:PSNOW_STRICT_LOG_SANITIZATION = '0'` (or remove the env var and revert
`Private/Write-PSNowStructuredLog.ps1` to the pre-Ex13 commit). The flag check
is a single `if` branch — reverting removes two lines without touching the
surrounding logic.

**Revert command:**
```powershell
git revert <ex13-commit-sha> --no-edit
```
