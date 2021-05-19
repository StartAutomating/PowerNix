Write-FormatView -TypeName 'PowerNix.Memory' -Property '% Free', 'MemoryFree', 'MemoryTotal' -ColorProperty @{
    <#'% Free' = {
        $percentFree = $_.MemoryPercentFree
        if ($percentFree -lt 50)  { 'Success' }
        if ($percentFree -lt 75)  { 'Warning' }
        'Error'
    }#>     
} -AlignProperty @{
    '% Free' = 'Left'
    'MemoryFree' = 'Center'
    'MemoryTotal' = 'Center'
} -VirtualProperty @{
    '% Free' = { [Math]::Round($_.MemoryPercentFree, 2) }
    'MemoryFree' = { '' + [Math]::Round($_.MemFree / 1gb, 2) + 'gb' } 
    'MemoryTotal' = { '' + [Math]::Round($_.MemTotal / 1gb, 2) + 'gb' }
}