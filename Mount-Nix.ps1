function Mount-Nix
{
    <#
    .Synopsis
        Mounts a device
    .Description
        Mounts a device on a Unix system.
        Often requires the user to be running as root.
    .Example
        Mount-Nix -Device //computer/share/ -MountPoint /mnt/computer -FileSystemType cifs -Option rw # Must have the cifs-utils package installed.
    .Link
        Get-NixMount
    #>
    [OutputType([Nullable], [string])]
    [Cmdletbinding(SupportsShouldProcess,ConfirmImpact='High')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("Test-ForSlowScript", "", Justification="Written for User Clarity")]
    param(
    # The device.
    # When mounting a Samba share, the device is the name of the UNC path to the remote share.
    [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
    [string]
    $Device,

    # The mount point.
    # This describes where in the filesystem the device should be mounted.
    [Parameter(Mandatory,Position=1,ValueFromPipelineByPropertyName)]
    [string]
    $MountPoint,

    # The type of device
    [Parameter(Mandatory,Position=2,ValueFromPipelineByPropertyName)]
    [string]
    $FileSystemType,

    # The mount options.  These can either be strings or hashtables.
    # These are case sensative
    [Parameter(Position=3,ValueFromPipelineByPropertyName)]
    [Alias('Options')]
    [PSObject[]]
    $Option,

    # If set, will make the mount persistent, by adding it to /etc/fstab.
    # If -Credentials are provided, then will automatically create a credentials file
    [Parameter(ValueFromPipelineByPropertyName)]
    [switch]
    $Persistent,

    # The path to the file system table.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('FStabPath')]
    [string]
    $FileSystemTablePath = '/etc/fstab',

    # If set, will return the output from mount or the line added to the filesystemtable.
    [Parameter(ValueFromPipelineByPropertyName)]
    [switch]
    $PassThru,

    # The credential used to mount the device.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('Credentials')]
    [PSCredential]
    $Credential,

    # The dump frequency.  This is rarely used, and only required for persistent mounts.
    [int]
    $DumpFrequency = 0,

    # The pass number.  This is rarely used, and only required for persistent mounts.
    [int]
    $PassNumber = 0
    )

    process {
        $realOptions = @(
            foreach ($opt in $Option) {
                if ($opt -is [string]) {
                    $opt
                }
                if ($opt -is [Collections.IDictionary]) {
                    foreach ($o in $opt.GetEnumerator()) {
                        '' + $o.Key + '=' + $o.Value
                    }
                }
            }

            if ($Credential -and -not $Persistent) {
                "username=$($Credential.UserName)"
                "password=$($Credential.GetNetworkCredential().Password)"
            }
        ) -join ','

        if ($Persistent) {
            # If you want a mount to be -Persistent,
            # it has to be written to -FileSystemTablePath (by default /etc/fstab)
            if ($Credential) { # If we have a credential for a persistent mount,
                # we don't want to put it in a file _everyone_ can read.
                # Instead, let's create a hidden file beneath $home, with the last segment of the mountpount.
                $credFilePath = Join-Path $home ".$(@($MountPoint -split '/')[-1]).creds"
                $credFileContents = @( # Each line of this file should be outputted as a separate string:
                    "username=$($Credential.GetNetworkCredential().UserName)" # ( the username,
                    "password=$($Credential.GetNetworkCredential().Password)" # the password
                    # and the domain (if present)
                    $(if ($Credential.GetNetworkCredential().Domain) {
                        "domain=$($credential.GetNetworkCredential().Domain)"
                    })
                ) -join [Environment]::NewLine | # then we join all of the lines with the newlines from the current environemnt.
                    # (this prevents a file with windows linefeeds from accidentally being created in a Linux environment)
                    Set-Content  $credFilePath

                # We don't want _everyone_ to be able to read the creds file either.
                # So let's make sure chmod is a command
                $chmod = $ExecutionContext.SessionState.InvokeCommand.GetCommand('chmod', 'Application')
                # and if it is, change the permission to be 600 (current user can read/writem, no one else can)
                if ($chmod) {
                    & $chmod 600 "$credFilePath"
                }
                # Add the pointer to the credfile path to the real options
                $realOptions += ",credentials=$credFilePath"
            }

            # Compose the line that we will write to the -FileSystemTablePath.
            # It contains the device, mountpoint, filesystemtype, options, dumpfrequency, and passnumber separated by spaces.
            $line = $Device, $MountPoint, $FileSystemType, $realOptions, $dumpFrequency, $passNumber -join ' '
            if ($WhatIfPreference) { # If -WhatIf was passed,
                 return $line # return the line
            }

            foreach ($fileSystemTableLine in Get-Content -Path $FileSystemTablePath) {
                if ($fileSystemTableLine -eq $line) { # If the line already exists, return
                    return
                }
                if ($fileSystemTableLine -like "* $MountPoint *") {
                    Write-Warning "Potential Conflict for MountPoint $MountPoint"
                }
            }

            # Add the line to the file system table path
            Add-Content -Path $FileSystemTablePath -Value $line -PassThru:$PassThru
        } else {
            if ($WhatIfPreference) { # If -WhatIf was passed for a dynamic mount
                return "mount -t $FileSystemType $Device $MountPoint -o $realOptions" # return the command we'd run

            }
            Write-Verbose "mount -t $FileSystemType $Device $MountPoint -o $realOptions" # Write it to -Verbose
            mount -t $FileSystemType $Device $MountPoint -o $realOptions  | # Run it
                & { process  {
                    if ($PassThru) { # If -PassThru was passed
                        $_  | Get-NixMount -MountInfoText { $_ } # Turn this back into an object! (see Get-NixMount)
                    }
                } }
        }
    }
}
