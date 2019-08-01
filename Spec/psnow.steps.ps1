Given 'we have a (?<name>\S*) function' {
    param($name)
    #"$psscriptroot\public\$name.ps1" | Should Exist
    "$env:BHProjectPath/public/$name.ps1" | Should Exist
}

Given 'we have public functions' {
    $path = (get-item -path Env:BHProjectPath).Value
    "$path/public/*.ps1" | Should Exist
}