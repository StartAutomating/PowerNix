function Get-NixMemory
{
    <#
    .Synopsis
        Gets Unix Memory 
    .Description
        Gets Unix Memory Statistics
    .Example
        Get-NixMemory
    .Link
        Get-NixUptime
    #>
    [OutputType('PowerNix.Memory')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("Test-ForSlowScript", "", Justification="Written for User Clarity")]
    param()

    process {
        if (-not (Test-Path '/proc/meminfo')) { # If /proc/meminfo doesn't exist
            Write-Error "/proc/meminfo not found" -ErrorId File.Missing # write and error and return
            return
        }

        #region Read /proc/meminfo
        Get-Content /proc/meminfo |
            & { 
                begin { $out = [Ordered]@{PSTypeName='PowerNix.Memory'} } # We want to give our output the typename of PowerNix.Memory
                process {
                    $key, $value = $_ -split ':', 2 # Each line is key:value
                    $value = ($value -replace '\skB') -as [long] # allow the values to be long, and replace kB
                    $value *= 1kb # multiply by kilobytes
                    $out[$key.Trim()] = $value # set the value
                }
                end {
                    [PSCustomObject]$out # Output the object.
                }
            }
        #endregion Read /proc/meminfo
    }
}

