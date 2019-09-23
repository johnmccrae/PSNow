<#

    Setup - to use this demo module you need do only 2 things:
    1) Go to https://api.nasa.gov, scroll down a bit from the top and create an account - you'll get an API key back immediately.
    2) Take that api key and burn it to an environment variable under PowerShell
        - Set-Item -Path Env:NasaKey -Value <your key value>


#>

$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    #Foreach ($import in $Public) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename



