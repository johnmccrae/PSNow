# Security & Secret Hygiene

This document outlines secret handling practices and safeguards for PSNow.

## Golden Rule

**Never commit credentials, API keys, certificates, or secrets to version control.**

## Current Practices

### Environment Variables (Correct Pattern)

Build/publish tasks use environment variables for secrets:

```powershell
# In build.psake.ps1
$patToken = $env:BHAzureBuildPassword
$apiKey = $env:BHPSGalleryKey
```

**Why this is safe:**
- Environment variables are set locally or in CI/CD systems (e.g., GitHub Secrets, Azure Pipelines).
- They are never committed to the repository.
- Scripts can reference them without embedding them.

**When adding new secrets:**
1. Define an environment variable in your CI/CD pipeline (do not commit the actual secret).
2. Reference it in PowerShell scripts with `$env:VariableName`.
3. Add the variable name to this document and to CI/CD platform docs (e.g., `BHPSGalleryKey` → GitHub Secrets docs).

### Certificates (Local, Not Committed)

The `Certs/` directory contains only `openssl.cfg` (a template configuration file).

- Self-signed certificates are created at runtime in `Cert:\CurrentUser\My` and `Cert:\CurrentUser\Root`.
- They are **never stored in the repository**.
- This is correct behavior.

## `.gitignore` Protection

The `.gitignore` file now explicitly lists common secret file patterns to prevent accidental commits:

- `.env`, `.env.local` (environment files)
- `*.pem`, `*.key`, `*.pfx`, `*.p12`, `*.jks`, `*.crt`, `*.cer` (certificates & keys)
- `secrets.json`, `appsettings.*.json` (config files with secrets)
- `.azure/`, `.aws/`, `.ssh/` (cloud provider and SSH credential folders)
- `credentials.json`, `credentials.xml` (explicit credential files)

## Scanning & Validation

### What Was Checked

1. ✓ No hardcoded credentials in PowerShell scripts.
2. ✓ Secrets referenced via environment variables (not stored in code).
3. ✓ `Certs/` directory contains no private keys.
4. ✓ `.gitignore` updated with comprehensive secret patterns.

### What to Monitor

Before committing any changes, scan staged commits for secret patterns:

**Windows (PowerShell):**
```powershell
git diff --cached | Select-String -Pattern 'password|secret|token|api.?key|credential' -IgnoreCase
```

**macOS / Linux (Bash):**
```bash
git diff --cached | grep -iE 'password|secret|token|api.?key|credential'
```

If no matches are found, you're clear. Otherwise, review before commit.

## Scaffolded Modules

Modules created via `New-PSNowModule` inherit this security posture:

- Generated `.gitignore` includes similar safe patterns.
- Build scripts use environment variables for secrets.
- Recommend documenting secret setup in generated `Build/README.md`.

## Checklist for Code Reviews

Before merging any PR:

- [ ] No `.env`, `*.pem`, `*.key`, `*.pfx` files added.
- [ ] No hardcoded credentials (passwords, API keys) in code.
- [ ] Any new build/deploy task uses environment variables for secrets.
- [ ] Corresponding environment variable is documented (in CI/CD docs or this file).

## What to Do If You Accidentally Commit a Secret

1. **Do not push.** If it's in a local branch only:

   **Windows (PowerShell):**
   ```powershell
   git reset --soft HEAD~1
   # Remove the secret file, add to .gitignore
   git add .gitignore
   git commit -m "Add secret to gitignore"
   ```

   **macOS / Linux (Bash):**
   ```bash
   git reset --soft HEAD~1
   # Remove the secret file, add to .gitignore
   git add .gitignore
   git commit -m "Add secret to gitignore"
   ```

2. **If already pushed:**
   - Immediately rotate the credential (API key, token, etc.).
   - File an incident report.
   - Use tools like `git filter-branch` or GitHub's secret scanning to purge the history.

## References

- [OWASP: Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub: Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- PowerShell Secure Strings: Use `ConvertTo-SecureString` for in-memory secrets (not for storage).
