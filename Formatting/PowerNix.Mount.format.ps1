Write-FormatView -TypeName PowerNix.Mount -Property TargetPath, SourceDevice, FileSystemType, Options -VirtualProperty @{
    Options = {
        
        @(
        foreach ($opt in $_.Options) {
             if ($opt -is [string]) {$opt}
             if ($opt -is [Collections.IDictionary]) {
                foreach ($o in $opt.GetEnumerator()) {
                    if ($o.Key -match 'password') {
                        '' + $o.Key + '=' + ('*' * 8)
                    } else {
                        '' + $o.Key + '=' + $o.Value
                    }
                }
             }
        }
        ) -join [Environment]::NewLine
    }
} -Wrap
