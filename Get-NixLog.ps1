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

    .Example
        # Group all logs in the current syslog file by minute
        Get-NixLog -LogFilePath '/var/log/syslog' | Group-Object {$_.date.minute}

    #>
    [OutputType([Nullable], [string])]
    [Cmdletbinding(DefaultParameterSetName='Journalctl')]
    param(
    # The path to the logfile read by.
    [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='LogFile')]
    [Alias("Fullname")]
    [ValidateScript(
        {
            #Faster method for Resolve-Path
            $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($PSItem) -as [bool]
        }
    )]
    [string]
    $LogFilePath,

    # A Time based filter for logs before a date. Example timestamp is "2020-04-08 17:12:00"
    # Could also be yesterday, today, tomorrow
    # [datetime]::now.ToString('s').Replace('T',' ')
    [Parameter(ParameterSetName='Journalctl',ValueFromPipelineByPropertyName)]
    [string]
    [alias('until')]
    $Before,

    # A Time based filter for logs after a date. Example timestamp is "2020-04-08 17:12:00"
    # Could also be yesterday, today, tomorrow
    # [datetime]::now.ToString('s').Replace('T',' ')
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

    begin{
        # Contains patterns to identify the logging type
        # Name captures will be declared as variables
        # for example (?<hostname>\w+) will populate hostname
        $logPatterns = [ordered]@{
            Syslog = '(?<date>^\w.+:\d{2})\s(?<hostname>[a-zA-Z0-9][-a-zA-Z0-9_]+)\s(?<process>.+?:)\s(?<message>.*)'
        }
        # Contains the script blocks to handle a given log type
        $logReaders = [ordered]@{
            Syslog = {  #Match a pid for the format [<number>] and assign it to the group process_pid
                        $process_pid = if($process -match '(?<process_pid>(?<=\[)(?>.+\d)(?=\]))' ){$matches.process_pid -as [int]} else{$null}
                        #Match a process until a [ or :
                        $process_name = if($process -match '(?<process_name>^.+\w(?=\[|:))'){$matches.process_name}
                        [PSCustomObject][ordered]@{
                            PsTypeName = "PowerNix.Log.Syslog"
                            DATE =  [datetime]::ParseExact($date, "MMM dd HH:mm:ss", [CultureInfo]::InvariantCulture)
                            HOSTNAME = $hostname
                            PROCESS = $process_name
                            PID = $process_pid
                            MESSAGE = $message
                        }
                     }
        }
    }
    process {
        if($LogFilePath) {
            $isfirstline = $true
            $logReader = ''
            $LogFileContent = Get-Content -Path $LogFilePath
            $LogFileContent |
            & { process {
                if($isfirstline) {
                    $isfirstline = $false
                    # look through each log file pattern
                    foreach ($kv in $logPatterns.GetEnumerator()){
                        # if the pattern matches select the log type
                        if( $PSItem -match $kv.Value ) {
                            $logReader = $kv.Key
                            break
                        }
                    }
                    if (-not $logReader) {
                        Write-Error -Message "Unable to parse log" -TargetObject $LogFilePath
                    }
                }

                if (-not $logPatterns[$logReader] -or -not $logReaders[$logReader]){
                    return
                }

                foreach ($match in [regex]::Matches($PSItem, $logPatterns[$logReader]) ){
                    foreach ($group in $match.groups){
                        $ExecutionContext.SessionState.PSVariable.Set($group.name, $group.value)
                    }
                    & $logReaders[$logReader]
                }
            } }
        } else {
            # check that the system is using systemd
            if (-not (pidof systemd)) {
                Write-Error "Systemd not detected must use -LogFilePath" -ErrorId File.Missing
                return
            }
            $journalArgs = @('-r','-o','json'
            if($UTC){"--utc"}
            if($KernalOnly){"--dmesg"}
            if($Boot){"-b","$Boot"}
            if($LineNumber){"-n","$LineNumber"}
            if($Identifier){foreach($i in $Identifier){"-t","$i"}}
            if($Unit){foreach($u in $Unit){"-u","$u"}}
            if($Before){"-U","`"$Before`""}
            if($After){"-S","`"$After`""}
            if($Priority)
            {
                if ($Priority.Count -gt 1)
                {
                    "-p","$($priority[0])..$($priority[-1])"
                } else
                {
                    "-p","$Priority"
                }
            }
            )#end of the array
            # Invoking journalctl with arguements from parameters.
            $results = journalctl @journalArgs
            convertfrom-json -InputObject $results |
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

