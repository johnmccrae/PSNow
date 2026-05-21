# Backlog for PSNow Enhancements

## Item 1: Improve Logging for `Invoke-Plaster` Operation
**Description**: Enhance the structured logging for the `Invoke-Plaster` operation to include additional diagnostic fields such as timestamp and user context.

**Acceptance Criteria**:
- [ ] Add `timestamp` and `user` fields to the log entries.
- [ ] Update the `New-PSNowModule` function to include these fields in verbose logs.
- [ ] Ensure logs are backward-compatible with existing parsers.
- [ ] Add unit tests to validate the new fields.

**Code Links**:
- [Private/Get-PSNowEnvironmentVariables.ps1](Private/Get-PSNowEnvironmentVariables.ps1)
- [tests/Common/Environment.tests.ps1](tests/Common/Environment.tests.ps1)

---

## Item 2: Validate Plaster Template Compatibility
**Description**: Ensure all Plaster templates (`Basic`, `Extended`, `Advanced`) are compatible with the latest Plaster version.

**Acceptance Criteria**:
- [ ] Test all templates with Plaster 1.1.3 and the latest version.
- [ ] Update `dependencies.md` with compatibility notes.
- [ ] Add integration tests for template validation.

**Code Links**:
- [PlasterTemplate/Basic.xml](PlasterTemplate/Basic.xml)
- [PlasterTemplate/Extended.xml](PlasterTemplate/Extended.xml)
- [PlasterTemplate/Advanced.xml](PlasterTemplate/Advanced.xml)

---

## Item 3: Extend Environment Helper Logic
**Description**: Add support for detecting additional operating systems in `GetPSNowOs`.

**Acceptance Criteria**:
- [ ] Add detection for `FreeBSD` and `Solaris`.
- [ ] Update the `Unsupported Operating system!` error message to include these platforms.
- [ ] Add unit tests for the new OS checks.

**Code Links**:
- [Private/Get-PSNowEnvironmentVariables.ps1](Private/Get-PSNowEnvironmentVariables.ps1)
- [tests/Common/Environment.tests.ps1](tests/Common/Environment.tests.ps1)

---

## Item 4: Automate Dependency Validation
**Description**: Automate the validation of pinned dependencies in `build.depend.psd1` to ensure they are up-to-date.

**Acceptance Criteria**:
- [ ] Create a script to check for newer versions of dependencies.
- [ ] Log warnings for outdated dependencies.
- [ ] Add a CI step to run the validation script.

**Code Links**:
- [Build/build.depend.psd1](Build/build.depend.psd1)
- [scripts/validate.ps1](scripts/validate.ps1)

---

## Item 5: Enhance Build and Test Documentation
**Description**: Improve the clarity and structure of the build and test documentation.

**Acceptance Criteria**:
- [ ] Add a troubleshooting section for common build/test issues.
- [ ] Include examples for running tests on specific modules.
- [ ] Ensure all commands are cross-platform compatible.

**Code Links**:
- [ai-track-docs/build-test.md](ai-track-docs/build-test.md)
- [readme.md](readme.md)