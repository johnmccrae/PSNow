# Security Guide — PSNow

This document describes the security controls in PSNow, how to report vulnerabilities, and guidance for contributors.

---

## Threat Model

PSNow is a local developer tool. Its attack surface is the two public functions:
`New-PSNowModule` and `Find-PSNowModule`. Both run in the operator's own user context.
The primary risks are:

| Threat | Affected parameter | Mitigation |
|---|---|---|
| Path traversal via module name | `-NewModuleName` | `ValidatePattern` allowlist |
| Path traversal via root path | `-ModuleRoot` | `GetFullPath` canonicalization |
| Unintended state changes | any | `SupportsShouldProcess` / `-WhatIf` |
| Credential leakage in build | `$env:BHAzureBuildPassword` | Read from env var; never hardcoded |

---

## Security Controls

### 1. `$NewModuleName` — ValidatePattern (PR #45)

`-NewModuleName` is validated against `^[a-zA-Z][a-zA-Z0-9._-]{0,63}$` before
the function body runs. This blocks:

- Path separators (`/`, `\`)
- Parent-directory traversal (`..`)
- Names starting with `.`
- Special characters that could affect `New-Item` or Plaster

**File:** `Public/New-PSNowModule.ps1`

### 2. `$ModuleRoot` — Path Canonicalization (PR #45)

When `-ModuleRoot` is supplied by the caller, it is normalized via
`[System.IO.Path]::GetFullPath()` before any directory or file operations run.
This collapses `..` sequences (e.g. `C:\safe\..\Windows\System32` →
`C:\Windows\System32` — still visible to the operator, but no longer hidden).
Tilde (`~`) is expanded to `$HOME` before canonicalization.

The default paths (`c:\modules`, `~/modules`) are not affected.

**File:** `Public/New-PSNowModule.ps1`

### 3. ShouldProcess / `-WhatIf` Support (PR #45)

`New-PSNowModule` is decorated with `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]`.
All state-changing operations (directory creation, Plaster invocation,
`currentmodules.txt` update) are guarded by `$PSCmdlet.ShouldProcess(...)`.

This allows operators to dry-run the command:

```powershell
New-PSNowModule -NewModuleName 'MyModule' -BaseManifest Advanced -WhatIf
```

It also removes the suppressed `PSUseShouldProcessForStateChangingFunctions`
PSSA violation that previously masked this gap.

**File:** `Public/New-PSNowModule.ps1`

---

## Build Credential Handling

The `PublishAzure` task in `Build/build.psake.ps1` reads credentials from
environment variables (`$env:BHAzureBuildUser`, `$env:BHAzureBuildPassword`)
and converts the PAT to a `SecureString` before passing it to `Publish-Module`.
The plaintext token is never written to disk or logged.

`PSAvoidUsingConvertToSecureStringWithPlainText` is suppressed on
`build.psake.ps1` because the plaintext origin is an env var (not a literal
string). This is the correct pattern for CI credential injection.

---

## Reporting a Vulnerability

Open a GitHub issue with the **security** label. For sensitive disclosures,
email the repository owner directly via the GitHub profile page.

---

## Extension Guidance

When adding new public parameters that accept file paths or names:

1. Add `[ValidatePattern(...)]` to restrict to safe characters.
2. Call `[System.IO.Path]::GetFullPath()` on user-supplied paths before use.
3. Add `SupportsShouldProcess` to any function that creates, modifies, or
   deletes files or directories.
4. Add corresponding tests in `tests/Unit/<FunctionName>.Security.tests.ps1`.
