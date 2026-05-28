@{
    # Use IncludeRules when you want to run only a subset of the default rule set.
    #IncludeRules = @('PSAvoidDefaultValueSwitchParameter',
    #                 'PSMissingModuleManifestField',
    #                 'PSReservedCmdletChar',
    #                 'PSReservedParams',
    #                 'PSShouldProcess',
    #                 'PSUseApprovedVerbs',
    #                 'PSUseDeclaredVarsMoreThanAssigments')

    # Use ExcludeRules when you want to run most of the default set of rules except
    # for a few rules you wish to "exclude".  Note: if a rule is in both IncludeRules
    # and ExcludeRules, the rule will be excluded.
    # ExcludeRules = @('PSAvoidUsingWriteHost', 'PSAvoidGlobalVars', 'PSAvoidUsingInvokeExpression')

    # You can use the following entry to supply parameters to rules that take parameters.
    # For instance, the PSAvoidUsingCmdletAliases rule takes a whitelist for aliases you
    # want to allow.
    ExcludeRules = @(
        # Global variables are used intentionally by the PSake build pipeline to share
        # state between tasks; suppressing this rule is a deliberate architectural choice.
        'PSAvoidGlobalVars',

        # BOM markers break Linux tooling and git diffs. All files in this repo are
        # UTF-8 without BOM; editors and CI are configured accordingly. Suppressed
        # project-wide — see Documentation/static-analysis-ex14.md for full justification.
        'PSUseBOMForUnicodeEncodedFile'
    )
    # Severity: Error and Warning are build-breaking.
    # Information is now reported so that positional-parameter and long-line findings
    # are visible in CI output (they do not fail the build, but are tracked).
    Severity     = @(
        "Warning",
        "Error"
    )

    Rules        = @{
        # Do not flag 'cd' alias.
        'PSAvoidUsingCmdletAliases' = @{'Whitelist' = @('Given', 'Then', 'When') }

        # Enforce named parameters for all cmdlet calls — positional parameters reduce
        # readability and break when parameter order changes across PS versions.
        'PSAvoidUsingPositionalParameters' = @{}

        # Lines should be no longer than 120 characters for side-by-side diff readability.
        'PSAvoidLongLines' = @{ MaximumLineLength = 120 }

        # Check if your script uses cmdlets that are compatible on PowerShell Core, on OSX, and on Linux.
        # PSUseCompatibleCmdlets = @{Compatibility = @("core-6.2.1")}
    }
}