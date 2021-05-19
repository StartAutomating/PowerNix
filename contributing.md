In order to contribute, please know a little bit of PowerShell and a little bit of Linux.

### Command Naming

Commands should be logically named using the PowerShell verb-noun convention.  
Most commands are expected to be prefixed with the noun -Nix, for example Get-NixMount

### Command Structure

Commands will often read or write a file or call an existing executable.  
Output should be processed and turned into property bags from any given command.
The property bags should have one or more .PSTypeNames that describe the object outputted.  
For example, Get-NixMount returned property bags decorated with the typename 'PowerNix.Mount'

### Adding Formatting and Types


Formatting and Types are built using [EZOut](https://github.com/StartAutomating/EZOut).  

To build your own:

~~~PowerShell
# Change directories to the repository root.
Install-Module EZOut -Scope CurrentUser # ( this only needs to be run every once in a while)
Import-Module EZOut                     # ( this needs to run each session) 
.\PowerNix.ezformat.ps1                 # ( this needs to run whenever you change formats or types)
~~~

#### Adding Formatting

Formatting exists in the /Formatting subdirectory of the repository.
Format source files are named Typename.format.ps1 files
(e.g. PowerNix.format.ps1)

#### Adding Types

Types exist with in the /Types subdirectory of the repository.
Types are in subdirectories with each type name.  For instance /Types/PowerNix.Memory
Most script files within this directory become script methods, unless named get_ or set_, in which case they become properties.

For example:
~~~PowerShell
#/Types/PowerNix.Memory/get_MemoryPercentFree.ps1
($this.MemFree / $this.MemTotal) * 100
~~~

Alias.psd1 contains a list of Alias properties, where the key is the name of the alias and the value is the original property, for example:

~~~PowerShell
#/Types/PowerNix.Memory/Alias.psd1
@{
    MemoryFree  = 'MemFree'
    MemoryTotal = 'MemTotal'
}
~~~


