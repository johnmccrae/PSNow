@{
    # Strict settings applied to the scripts/ directory.
    # Differences from PSScriptAnalyzerSettings.psd1 (base config):
    #   - PSUseBOMForUnicodeEncodedFile is NOT excluded (enforce BOM or inline-suppress with justification)
    #   - PSAvoidUsingPositionalParameters is enforced (Information severity)
    #   - Severity expanded to include Information in addition to Warning and Error
    #
    # Inline suppressions in source files are accepted ONLY when accompanied by
    # a Justification= comment explaining why the rule does not apply.

    ExcludeRules = @(
        'PSAvoidGlobalVars'
        # PSUseBOMForUnicodeEncodedFile intentionally NOT excluded here.
        # Files that contain only ASCII characters must suppress this rule
        # inline with a documented Justification.
    )

    Severity = @(
        'Warning'
        'Error'
        'Information'
    )

    Rules = @{
        # Do not flag 'cd' alias.
        'PSAvoidUsingCmdletAliases' = @{ 'Whitelist' = @('Given', 'Then', 'When') }
    }
}
