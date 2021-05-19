function Get-NixUptime
{
    <#
    .Synopsis
        Gets uptime for a Unix machine
    .Description
        Gets the uptime for a Unix machine, based off of the content of /proc/uptime.
    .Example
        Get-NixUptime
    .Link
        Get-NixMemory
    #>
    [OutputType('PowerNix.Uptime')]
    param()

    process {
        #region Check File Exists
        if (-not (Test-Path '/proc/uptime')) {
            Write-Error "Missing '/proc/uptime'" -ErrorId File.Missing
            return
        }
        #endregion Check File Exists

        $uptime, $idleTime = @(Get-Content '/proc/uptime' -Raw) -split ' '
        $uptime = [Timespan]::FromSeconds($uptime)
        [PSCustomObject]@{
            PSTypeName = 'PowerNix.Uptime'
            UpTime = $uptime
            BootDateTime = ([Datetime]::Now - [Timespan]$uptime)
        }
    }
}
