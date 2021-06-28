function Get-NixLog
{
    <#
    .Synopsis
        Gets log information from journalctl or syslog formatted logs.
    .Description
        Gets log via journalctl produced by the journald service which is standard on all distros that use systemd.
        Unless the -LogFilePath parameter is used, then it defaults to regex of the Syslog format.
    .Example
        Get-NigLog # returns all logs unfiltered from journald
    .Example
        Get-NixLog | Where {$psitem }
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
    [string]
    [alias('until')]
    $Before,

    # A Time based filter for logs after a date. Example timestamp is "2020-04-08 17:12:00"
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [string]
    [alias('since')]
    $After,

    # Explicitly require logs in UTC
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [switch]
    $UTC,

    # Request only kernel logs like dmesg
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [switch]
    [alias('dmesg')]
    $KernalOnly,

    # Offset number of the boot logs to look at. 0 is current boot, -1 is previous, etc.
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [int]
    [alias('b')]
    $Boot,

    # Number of lines to show
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [uint]
    [alias('n')]
    $LineNumber,

    # The specific syslog identifier you are looking at filtering. Can provided multiple identifiers
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [string[]]
    $Identifier,

    # The specific Systemd unit you are looking at filtering. Can provided multiple units
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [string[]]
    $Unit,

    # The priority of the logs you want to retrieve.
    # "emerg" (0), "alert" (1), "crit" (2), "err" (3), "warning" (4), "notice" (5), "info" (6), "debug" (7).
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [string[]]
    $Priority
    )

    process {
        if($LogFilePath) {
            $LogFileContent = Get-Content -Path $LogFilePath

            $LogFileContent |
            & { process {
                #Split the syslog file by date, hostname, process to the first :, and message
                $null, $date, $hostname, $process, $message = $PSItem -split '(?<date>^\w.+:\d{2})\s(?<hostname>\w+)\s(?<process>.+?:)\s(?<message>.*)'
                #Match a pid for the format [<number>] and assign it to the group process_pid
                $process_pid = if($process -match '(?<process_pid>(?<=\[)(?>.+\d)(?=\]))' ){$matches.process_pid} else{$null}
                #Match a process until a [ or :
                $process_name = if($process -match '(?<process_name>^.+\w(?=\[|:))'){$matches.process_name}
                [PSCustomObject][ordered]@{
                    DATE = $date
                    HOSTNAME = $hostname
                    PROCESS = $process_name
                    PID = $process_pid
                    MESSAGE = $message
                }
            } }
        } else {
            # check that the system is using systemd
            if (-not (pidof systemd)) {
                Write-Error "Systemd not detected must use -LogFilePath" -ErrorId File.Missing
                return
            }
            $journalArgs = [System.Text.StringBuilder]::new()
            $null = $journalArgs.Append('-r -o json')
            if($UTC){$null = $journalArgs.Append(" --utc ")}
            if($KernalOnly){$null = $journalArgs.Append(" --dmesg ")}
            if($Boot){$null = $journalArgs.Append(" -b $Boot ")}
            if($LineNumber){$null = $journalArgs.Append(" -n $LineNumber ")}
            if($Identifier){foreach($i in $Identifier){ $null = $journalArgs.Append(" -t $i ")}}
            if($Unit){foreach($u in $Unit){ $null = $journalArgs.Append(" -u $u ")}}
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

