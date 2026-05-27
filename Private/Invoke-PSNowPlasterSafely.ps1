# Invokes Plaster with the supplied parameter splat. If Plaster raises a
# ParameterBindingException for a parameter that is present in the splat,
# that parameter is removed and the call is retried. This handles template
# manifests that do not declare every optional parameter, without requiring
# the caller to know which parameters each manifest supports.
function Invoke-PSNowPlasterSafely {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PlasterParams
    )

    $params = $PlasterParams.Clone()

    while ($true) {
        try {
            Invoke-Plaster @params -Force -Verbose
            return
        }
        catch [System.Management.Automation.ParameterBindingException] {
            $missingParameter = [System.Text.RegularExpressions.Regex]::Match(
                $_.Exception.Message,
                "parameter name '([^']+)'",
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            ).Groups[1].Value

            if ([string]::IsNullOrWhiteSpace($missingParameter) -or -not $params.ContainsKey($missingParameter)) {
                throw
            }

            $params.Remove($missingParameter) | Out-Null
        }
        catch {
            throw
        }
    }
}
