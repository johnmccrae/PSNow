@{
    # Strict settings — used by Build/Invoke-PSNowAutoFix.ps1 for local developer analysis.
    # These settings are NOT used in CI builds; CI uses PSScriptAnalyzerSettings.psd1
    # (Warning + Error only) so that Information-level findings in test helpers do not
    # break the pipeline.
    #
    # Run locally:
    #   Invoke-ScriptAnalyzer -Path .\Public, .\Private, .\Build -Settings .\Build\PSScriptAnalyzerSettings.Strict.psd1 -Recurse -Severity @('Error','Warning','Information')

    ExcludeRules = @(
        # See PSScriptAnalyzerSettings.psd1 for justification of each suppression.
        'PSAvoidGlobalVars',
        'PSUseBOMForUnicodeEncodedFile'
    )

    # All three severities — this surfaces Information-level findings that are hidden
    # in CI to keep the build clean.
    Severity     = @(
        'Warning',
        'Error',
        'Information'
    )

    Rules        = @{
        'PSAvoidUsingCmdletAliases'         = @{ Whitelist = @('Given', 'Then', 'When') }

        # Named parameters — positional parameters reduce readability and can break
        # silently when parameter order changes across PS versions.
        'PSAvoidUsingPositionalParameters'  = @{}

        # Line length — 120 chars maximum for readable side-by-side diffs.
        'PSAvoidLongLines'                  = @{ MaximumLineLength = 120 }
    }
}
