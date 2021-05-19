foreach ($file in Get-ChildItem -LiteralPath $psScriptRoot -Recurse -Filter *-*.ps1) {
    . $file.Fullname
}



if (-not $PSVersionTable.Platform -or $PSVersionTable.Platform -ne 'Unix') {
    Write-Warning "PowerNix is not running on Unix.  Most functions will not work."
}