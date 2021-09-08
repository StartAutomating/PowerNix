function Get-NixComputer {
    <#
    .Synopsis
        Gets kernel info from a Linux machine
    .Description
        Gets the kernel info from the current Linux machine using the hostnamectl utility.
    .Example
        Get-NixComputer # Get the current kernel
    .Link

    #>
    param(
    )

    process {
        try {
            $hostnamectlOutput = hostnamectl
            $computerInfo = [Ordered]@{PSTypeName = 'PowerNix.Computer' }
            foreach ($line in $hostnamectlOutput) {
                $key, $value = $line.split(': ')
                $key = $key -replace '\s'
                $computerInfo[$key] = $value -replace '^"' -replace '"$'
            }
            [PSCustomObject]$computerInfo
        } catch {
            Write-Error 'Failed to run hostnamectl.'
        }
    }
}
