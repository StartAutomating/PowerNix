function Get-NixLog
{
    <#
    .Synopsis
        Gets log information from journalctl
    .Description
        Gets log via journalctl produced by the journald service which is standard on all distros that use systemd.
    .Example
        Get-NigLog # returns all logs unfiltered
    .Example
        Get-NixLog | Where {$psitem }
    .Link
        Get-NixUptime
    #>
    [OutputType([Nullable], [string])]
    [Cmdletbinding(DefaultParameterSetName='Journalctl')]
    param(
    # The path to the logfile read by.
    [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='LogFile')]
    [System.IO.FileInfo]
    $LogFilePath,

    # A Time based filter for logs before a date. Example timestamp is "2020-04-08 17:12:00"
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [Parameter(ParameterSetName='LogFile',ValueFromPipelineByPropertyName)]
    [string]
    $Before,

    # A Time based filter for logs after a date. Example timestamp is "2020-04-08 17:12:00"
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [Parameter(ParameterSetName='LogFile',ValueFromPipelineByPropertyName)]
    [string]
    $After,

    # The priority of the logs you want to retrieve.
    # "emerg" (0), "alert" (1), "crit" (2), "err" (3), "warning" (4), "notice" (5), "info" (6), "debug" (7).
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [Parameter(ParameterSetName='LogFile',ValueFromPipelineByPropertyName)]
    [string[]]
    $Priority
    )

    process {
        if($LogFilePath) {
            #some regex
            #some file check
        } else {
            # check that the system is using systemd
            if (-not (pidof systemd)) {
                Write-Error "Systemd not detected must use -LogFilePath" -ErrorId File.Missing
                return
            }
            $journalArgs = [System.Text.StringBuilder]::new()
            $null = $journalArgs.Append('-r -o json')
            if($Before){$null = $journalArgs.Append(" -U `"$Before`"")}
            if($After){$null = $journalArgs.Append(" -S `"$After`"")}
            if($Priority)
            {
                if ($Priority.Count -gt 1)
                {
                    $null = $journalArgs.Append(" -p $($priority[0])..$($priority[-1])")
                } else
                {
                    $null = $journalArgs.Append(" -p $Priority")
                }
            }
            # Invoking journalctl with arguements from parameters.
            Invoke-Expression "journalctl $($journalArgs.tostring())" | convertfrom-json |
            & {
                process {
                    $journalcltLogs = [Ordered]@{PSTypeName='PowerNix.Logs'} # create a dictionary to hold logs.
                    foreach($v in $psitem.psobject.properties) {
                        $name = $($v.name -replace '^_{1,2}') # Removing all leading underscores
                        $value = $v.value
                        $journalcltLogs[$name] = $value
                    }
                    [PSCustomObject]$journalcltLogs
                }
            }
        }
    }
}

