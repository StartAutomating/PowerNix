function Get-NixDistro
{
    <#
    .Synopsis
        Gets Distro info from a Unix machine
    .Description
        Gets the Distribution info from the current Unix machine, which is found in files beneath /etc/*release*.
    .Example
        Get-NixDistro
    .Link
        Get-NixUptime
    #>
    [OutputType('PowerNix.Uptime')]
    param(
    # If set, will force a refresh of this cached distribution information.
    [switch]
    $Force
    )

    process {
        #region Check File Exists
        if (-not (Test-Path '/etc/*release*')) {
            Write-Error "No release files beneath /etc'" -ErrorId File.Missing
            return
        }
        #endregion Check File Exists

        if ($Force) { # If -Force is passed, 
            $Script:CachedDistroInfo = $null # clear the cache.
        }
        if (-not $Script:CachedDistroInfo) { # If nothing is in the cache
            $releaseFileInfo = [Ordered]@{PSTypeName='PowerNix.Distro'} # create a dictionary to hold release info.
            Get-ChildItem -Path /etc -Filter os-release -File | # Find the os-release file
                & { process {
                    $fileLines = [IO.File]::ReadAllLines($_.fullname) # Parse it out
                    foreach ($line in $fileLines) { 
                        $key, $value = $line -split '=', 2
                        $releaseFileInfo[$key] = $value -replace '^"' -replace '"$'
                    }
                } }        
            $Script:CachedDistroInfo = [PSCustomObject]$releaseFileInfo
        }
        $Script:CachedDistroInfo
    }
}

