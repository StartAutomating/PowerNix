function Get-NixKernel {
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
            $kernelDetails = hostnamectl
            return [PSCustomObject]@{
                Kernel = $kernelDetails[6].Split(': ')[-1]
                Arch   = $kernelDetails[7].Split(': ')[-1]
            }            

        } catch {
            Write-Error 'Failed to run hostnamectl.'
        }
    }
}