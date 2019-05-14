[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
param()
$moduleRoot = Resolve-Path "$PSScriptRoot\.."
#$myOutput = Resolve-Path "$PSScriptRoot\..\.."

$script:ModuleName = $ENV:BHProjectName

# $script:Source = Join-Path "$BuildRoot" $ModuleName
# $script:Source = Join-Path "$moduleRoot" $ModuleName
$Script:Source = "$moduleRoot"
$script:Output = Join-Path (Resolve-path "$PSScriptRoot\..\..") output
# $script:Output = Join-Path "$moduleRoot" output
$script:Destination = Join-Path $Output $ModuleName
$script:ModulePath = "$Destination\$ModuleName.psm1"
$script:ManifestPath = "$Destination\$ModuleName.psd1"
$script:Imports = ('classes' )
$script:TestFile = "$PSScriptRoot\output\TestResults_PS$PSVersion`_$TimeStamp.xml"
$global:SUTPath = $script:ManifestPath

Task Default WhereAmI
Task Build Clean, FullTests, CopyToOutput

Task Clean {
    $null = Remove-Item $Output -Recurse -ErrorAction Ignore
    $null = New-Item  -Type Directory -Path $Destination
}

Task InstallSUT {
    Invoke-PSDepend -Path "$PSScriptRoot\build.depend.psd1" -Install -Force
}

Task UnitTests {
    $TestResults = Invoke-Pester -Path Tests\*unit* -PassThru -Tag Build -ExcludeTag Slow
    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed [$($TestResults.FailedCount)] Pester tests"
    }
}

Task FullTests {
    $TestResults = Invoke-Pester -Path "..\Tests" -PassThru -OutputFormat NUnitXml -OutputFile $testFile -Tag Build

    PublishTestResults $testFile

    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed [$($TestResults.FailedCount)] Pester tests"
    }
}

Task WhereAmI {
    Write-Output "I am located at: $Script:Source"
    Write-Output "My Output Path is: $Output"
    Write-Output "My Destination path is: $Destination"
}

Task CopyToOutput {

    Write-Output "  Create Directory [$Destination]"
    $null = New-Item -Type Directory -Path $Destination -ErrorAction Ignore

    Get-ChildItem $source -File |
        where-object name -NotMatch "$ModuleName\.ps[dm]1" |
        Copy-Item -Destination $Destination -Force -PassThru |
        ForEach-Object { "  Create [.{0}]" -f $_.fullname.replace($PSScriptRoot, '')}

    Get-ChildItem $source -Directory |
        where-object name -NotIn $imports |
        Copy-Item -Destination $Destination -Recurse -Force -PassThru |
        ForEach-Object { "  Create [.{0}]" -f $_.fullname.replace($PSScriptRoot, '')}
}

Taks MakeHelp {

}
