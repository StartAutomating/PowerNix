function Get-NixMount
{
    <#
    .Synopsis
        Gets mounts
    .Description
        Gets existing filesystem mounts
    .Example
        Get-NixMount
    .Link
        Mount-Nix
    #>
    [OutputType('PowerNix.Mount')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("Test-ForSlowScript", "", Justification="Written for User Clarity")]
    param(
    # The path to the mount info filestream.  By default, this will be /proc/mounts.
    [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='MountInfoFile')]
    [string]
    $MountInfoPath = '/proc/mounts',

    # The text describing a mount
    [Parameter(Mandatory,ParameterSetName='MountInfoText',ValueFromPipelineByPropertyName)]
    [string[]]
    $MountInfoText
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'MountInfoFile') { # If we're getting mounts from a file
            if (-not (Test-Path $MountInfoPath)) { # check that it exists
                Write-Error "'$moduleInfoPath' not found" -ErrorId File.Missing # (error out if it doesn't).
                return
            }

            $MountInfoText = Get-Content $MountInfoPath # Get the mount info, line by line.
        }

        $MountInfoText | # Walk over each line
            & { process  {
                $source, $target, $fileSystem, $mountInfo, $null, $null =  $_ -split ' ' # split them up with multiple assignment.
                [PSCustomObject][Ordered]@{
                    # Decorate the output with the typename 'PowerNix.Mount' (this enables format/types files)
                    PSTypeName     = 'PowerNix.Mount'
                    Device         = $source
                    MountPoint     = $target
                    FileSystemType = $fileSystem
                    Options  = @( # Turn the options string into strings or objects.
                        $kvs = [ordered]@{} # Options can either be a key=value or a just a value.
                        foreach ($mnt in $mountInfo -split ',') { # Each option is separated by a comma.
                            if ($mnt.Contains('=')) { # If it's key-value
                                $k, $v = $mnt -split '='  # keep it with the other key-value pairs
                                $kvs[$k]=$v
                            } else {
                                $mnt # If it's a string, output it now.
                            }
                        }
                        if ($kvs.Count) { # If we had any key value pairs
                            # Output that collection.
                            # This will make .options:
                            # "stringOption1", "stringoption2", @{key1='value1';key2='value2'} # etc
                            $kvs
                        }
                    )
                }
            } }
    }
}