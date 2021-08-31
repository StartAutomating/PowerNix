function Get-NixComputer {
    <#
    .Synopsis
        Gets kernel info from a Linux machine
    .Description
        Gets the kernel info from the current Linux machine using the hostnamectl utility.
    .Example
        Get-NixKernel # Get the current kernel
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
                $key = $key.trimstart()
                $computerInfo[$key] = $value -replace '^"' -replace '"$'
            }    
            $computerInfo
        } catch {
            Write-Error 'Failed to run hostnamectl.'
        }
    }
}