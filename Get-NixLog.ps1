function Get-NixLog
{
    <#
    .Synopsis
        Gets log information from journalctl or syslog formatted logs.
    .Description
        Gets log via journalctl produced by the journald service which is standard on all distros that use systemd.
        If the -LogFilePath parameter is used then the command uses regex to parse in the Syslog format.
        Otherwise
    .Example
        # returns all logs unfiltered from journald
        Get-NigLog

        CURSOR                    : s=1032b59ef7f247819e0500ebe21424d3;i=19ac95;b=cab0af3b917244288fe2a15fc3b01
                                    a42;m=1767c381e6c;t=5c65195d4a866;x=2e08686703b082cb
        REALTIME_TIMESTAMP        : 1625428591945830
        MONOTONIC_TIMESTAMP       : 1608401821292
        BOOT_ID                   : <someBootID>
        MACHINE_ID                : <someGuid>
        HOSTNAME                  : ubuntu
        SELINUX_CONTEXT           : unconfined

        SYSTEMD_SLICE             : system.slice
        SYSLOG_FACILITY           : 3
        TRANSPORT                 : journal
        PRIORITY                  : 4
        CODE_FILE                 : ../src/resolve/resolved-dns-transaction.c
        CODE_LINE                 : 1047
        CODE_FUNC                 : dns_transaction_process_reply
        SYSLOG_IDENTIFIER         : systemd-resolved
        MESSAGE                   : Server returned error NXDOMAIN, mitigating potential DNS violation
                                    DVE-2018-0001, retrying transaction with reduced feature level UDP.
        PID                       : 899
        UID                       : 101
        GID                       : 103
        COMM                      : systemd-resolve
        EXE                       : /lib/systemd/systemd-resolved
        CMDLINE                   : /lib/systemd/systemd-resolved
        CAP_EFFECTIVE             : 0
        SYSTEMD_CGROUP            : /system.slice/systemd-resolved.service
        SYSTEMD_UNIT              : systemd-resolved.service
        SYSTEMD_INVOCATION_ID     : <someSystemD_ID>
        SOURCE_REALTIME_TIMESTAMP : 1625428591945762

    .Example
        # Returns logs from the /var/log/syslog in the following format
        Get-NixLog -LogFilePath /var/log/syslog

        DATE     : Jun  20 19:56:14
        HOSTNAME : ubuntu
        PROCESS  : powershell
        PID      : 16195
        MESSAGE  : {(7.1.3:1:80)
                [Perftrack_ConsoleStartupStart:PowershellConsoleStartup.WinStart.Informational] PowerShell
                console is starting up, }
    .Example
        # Uses native journalctl filtering to limit logs to a specifc time and priority
        # Like other PowerShell commands filtering on the cmdlet is faster than filtering later in the pipeline
        Get-NixLog -After "2021-06-21 00:00:00" -Priority err,warning | select -first 10

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
