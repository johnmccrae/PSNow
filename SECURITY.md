# Security Policy

## Secret / Credential Scanning

This repository uses **[gitleaks](https://github.com/gitleaks/gitleaks)** (v8+) to detect secrets and credentials committed to the repository.

### How it runs

| Where | When | Command |
|---|---|---|
| CI (Azure Pipelines) | Every PR targeting `main` or `walk-ex*` | `gitleaks detect --source . --config .gitleaks.toml` |
| Locally (optional) | Before push | `gitleaks detect --source . --config .gitleaks.toml` |

### Running locally

```powershell
# Install (Windows)
winget install gitleaks

# Scan working tree + full git history
gitleaks detect --source . --config .gitleaks.toml --no-banner

# Scan only uncommitted changes (faster pre-commit check)
gitleaks protect --staged --config .gitleaks.toml --no-banner
```

### Configuration

Rules are defined in `.gitleaks.toml`. The file extends gitleaks' built-in default ruleset.

### Known / allowlisted findings

| File (historical) | Commit | Reason |
|---|---|---|
| `Scaffold/Publish-MyPSModule.ps1` | `e316d996` | Hardcoded example PAT removed in a subsequent commit. Token treated as compromised and rotated. |
| `Public/Publish-MyPSModule.ps1` | `b4c4f8ff` | Same token, same remediation. |

These commits are listed in `.gitleaks.toml` under `[allowlist]` so CI scans do not block on them.

### Remediation process

If gitleaks finds a **new** secret:

1. **Rotate the credential immediately** — assume it is compromised.
2. Remove it from the working tree and rewrite history with `git filter-repo` if needed.
3. Add the commit SHA to the `[allowlist]` in `.gitleaks.toml` with a documented justification **only** after the credential has been rotated.
4. Open a security advisory if the credential had access to production systems.

### Reporting a vulnerability

Please do **not** open a public GitHub issue for security vulnerabilities. Instead, use [GitHub private vulnerability reporting](https://github.com/johnmccrae/PSNow/security/advisories/new) or email the maintainer directly.
