# PSNow Feature Flags

PSNow uses environment-variable feature flags to control optional runtime
behaviour. Each flag follows a standard lifecycle: **off by default → opt-in
to enable → explicit opt-out to override → remove when the guarded feature
is permanent**.

---

## Flag reference

| Flag | Default | Effect when ON |
|------|---------|----------------|
| `PSNOW_SAFE_MODE` | off | Suppresses the `"Your module was built at: [...]"` path output |
| `PSNOW_DISABLE_RETRY` | off | Bypasses the `Invoke-Plaster` retry loop; any `ParameterBindingException` propagates immediately |

---

## PSNOW_SAFE_MODE

### Purpose
Suppresses the informational path message written after a successful module
creation. Useful in automated pipelines where stdout is parsed and the extra
line would interfere.

### Default state
**Off.** The path message is written by default.

### How to enable
```powershell
$env:PSNOW_SAFE_MODE = '1'   # also accepts: true, yes, on
New-PSNowModule -NewModuleName MyMod -BaseManifest Basic
# no path line printed
```

### How to disable (restore default)
```powershell
Remove-Item Env:PSNOW_SAFE_MODE -ErrorAction SilentlyContinue
# or
$env:PSNOW_SAFE_MODE = '0'   # also accepts: false, no, off
```

### When to remove
Remove this flag (and the guard in `New-PSNowModule.ps1`) only if the
verbose path output is removed permanently from the function.

### Code location
`Public/New-PSNowModule.ps1` — search for `PSNOW_SAFE_MODE`

### Tests
`tests/Unit/New-PSNowModule.SafeToggle.tests.ps1`

---

## PSNOW_DISABLE_RETRY

### Purpose
Bypasses the retry loop that strips unknown dynamic Plaster parameters on
`ParameterBindingException`. When set, `Invoke-Plaster` is called exactly
once and any exception propagates immediately (fast-fail).

Use this in CI environments where you want immediate failure visibility
rather than silent parameter removal.

### Default state
**Off.** The retry loop is active; unknown parameters are stripped and
`Invoke-Plaster` is retried automatically.

### How to enable
```powershell
$env:PSNOW_DISABLE_RETRY = '1'   # also accepts: true, yes, on
New-PSNowModule -NewModuleName MyMod -BaseManifest Basic
# ParameterBindingException will now throw immediately
```

### How to disable (restore default)
```powershell
Remove-Item Env:PSNOW_DISABLE_RETRY -ErrorAction SilentlyContinue
# or
$env:PSNOW_DISABLE_RETRY = '0'   # also accepts: false, no, off
```

### When to remove
Remove this flag once the Plaster template parameter sets are stable and
the retry logic is no longer needed (i.e., all manifests declare exactly the
parameters that `New-PSNowModule` passes).

### Code location
`Public/New-PSNowModule.ps1` — search for `PSNOW_DISABLE_RETRY`

### Tests
`tests/Unit/New-PSNowModule.RetryToggle.tests.ps1`

---

## Adding a new flag

1. Choose an env-var name with the `PSNOW_` prefix.
2. Read it in the function using the truthy pattern:
   ```powershell
   $flagEnabled = [string]$env:PSNOW_MY_FLAG -match '^(1|true|yes|on)$'
   ```
3. Default must be **off** unless the new behaviour is immediately safe for
   all callers.
4. Add ON/OFF unit tests in `tests/Unit/`.
5. Add an entry to this document.
6. Set a removal criterion — flags should not live forever.
