Given 'we have a source file' {
    mkdir testdrive:\source -ErrorAction SilentlyContinue
    Set-Content 'testdrive:\source\something.txt' -Value 'Data'
    'testdrive:\source\something.txt' | Should Exist
}

Given 'we have a destination folder' {
    mkdir testdrive:\target -ErrorAction SilentlyContinue
    'testdrive:\target' | Should Exist
}

When 'we call Copy-Item' {
    { Copy-Item testdrive:\source\something.txt testdrive:\target } | Should Not Throw
}

Then 'we have a new file in the destination' {
    'testdrive:\target\something.txt' | Should Exist
}

Then 'the new file is the same as the original file' {
    $primary = Get-FileHash testdrive:\target\something.txt
    $secondary = Get-FileHash testdrive:\source\something.txt
    $secondary.Hash | Should Be $primary.Hash
}