function Dismount-Nix
{
    <#
    .Synopsis
        Dismounts a device
    .Description
        Dismounts a device on a Unix system.
        Often requires the user to be running as root.
    .Example
        Dismount-Nix -MountPoint /mnt/computer -Device //computer/share/
    .Example
        Dismount-Nix -All
    .Link
        Get-NixMount
    .Link
        Mount-Nix
    #>
    [OutputType([Nullable], [string])]
    [Cmdletbinding(SupportsShouldProcess,ConfirmImpact='High',DefaultParameterSetName='MountPoint')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("Test-ForSlowScript", "", Justification="Written for User Clarity")]
    param(
    # The mount point.
    # This describes where in the filesystem the device should be mounted.
    [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName,ParameterSetName='MountPoint')]
    [string]
    $MountPoint,

    # The device.
    # When mounting a Samba share, the device is the name of the UNC path to the remote share.
    [Parameter(Mandatory,Position=1,ValueFromPipelineByPropertyName,ParameterSetName='Device')]
    [Parameter(Position=1,ValueFromPipelineByPropertyName,ParameterSetName='MountPoint')]
    [string]
    $Device,

    # The mount options.  These can either be strings or hashtables.
    [Parameter(ValueFromRemainingArguments)]
    [Alias('Arguments')]
    [string[]]
    $ArgumentList,

    # If set, will make the mount persistent, by removing it to /etc/fstab.
    [Parameter(ValueFromPipelineByPropertyName)]
    [switch]
    $Persistent,

    # The type of device
    [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='Filesystem')]
    [string]
    $FileSystemType,

    # The path to the file system table.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('FStabPath')]
    [string]
    $FileSystemTablePath = '/etc/fstab',

    # This command removes all mount points
    # described in /proc/self/mountinfo
    # except for proc, devfs, devpts, sysfs, rpc_pipefs, and nfsd
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='Filesystem')]
    [switch]
    $All
    )
    process {
        if ($Persistent) { #If Persistent remove from $FileSystemTablePath
            $line = $Device, $MountPoint -join ' '
            if ($WhatIfPreference) {
                $match = (Get-Content -Path $FileSystemTablePath | Select-String -Pattern $line).line
                return $match
            }

            #There could be a better way of regexing this line as
            #a trailing / would break this simple matching
            Get-Content -Path $FileSystemTablePath |
                Select-String -Pattern $line -NotMatch |
                Set-Content -Path $FileSystemTablePath -PassThru:$PassThru
        }

        #Umount with Options
        if ($all){
            Write-Warning "About to remove all mounts"
            if ($WhatIfPreference) {
                'umount -a'
            }
            elseif ($PSCmdlet.ShouldProcess("Unmount All")) {
                umount -a
            }
            return            
        }
        if ($WhatIfPreference) {
            return "umount $Device $MountPoint"
        }
        if ($PSCmdlet.ShouldProcess("Dismount $device $MountPoint")) {
            umount $Device $MountPoint
        }
    }
}