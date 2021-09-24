function Out-Shebang
{
    <#
    .Synopsis
        Outputs a shebang
    .Description
        Outputs a shebang file and marks it as executable.

        Shebang files can have no extension and will be run with the interpreter declared on the first line.
    .Link
        https://en.wikipedia.org/wiki/Shebang_(Unix)
    .Example
        { "hello world" } | Out-Shebang
    .Example
        { "hello world $args" } | Out-Shebang -OutputPath ./HelloShebang
    .Example
        Out-Shebang -Script "mount -a" -OutputPath /etc/network/if-up.d/AutoMountNetworkDrives
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
    # The scripcontents of the Shebang.
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position=1)]
    [Alias('ScriptContents','ScriptBlock','Fullname','Definition')]
    [string]
    $Script,

    # The output path.  If not provided, the contents of the shebang will be outputted.
    [Parameter(ValueFromPipelineByPropertyName)]    
    [string]
    $OutputPath,

    # The interpreter.
    # If this is not provided, and a ScriptBlock or ExternalScript is piped in (or the alias -ScriptBlock is used)
    [string]
    $Interpreter = '/bin/sh'
    )

    process {
        # Determine if the $script was a path or not by checking if the file exists.
        $scriptPathExists = 
            try {
                Test-Path $Script -ErrorAction SilentlyContinue
            }
            catch { $null }
        
        # If the file exists and no interpreter was passed, attempt to auto-detect it.
        if ($scriptPathExists -and -not $PSBoundParameters['Interpreter']) {
            # |Extensions|Interpreter|
            # |-|-|
            switch ($scriptPathExists.Extension) { 
                .ps1 { $Interpreter = '/bin/pwsh' }            # |.ps1 | /bin/pwsh            |
                .js  { $Interpreter = '/usr/bin/env node' }    # |.js  | /usr/bin/env node    | 
                .py  { $Interpreter = '/usr/bin/env python3' } # |.py  | /usr/bin/env python3 |
                .sh  { $Interpreter = '/bin/sh' }              # |.sh  | /bin/sh python3      |
            }
        }
        
        #region Generate the Shebang Content
        $in, $myInv = $_, $MyInvocation # Assign the raw input object to $in.        
        if (-not $PSBoundParameters["Interpreter"]) { # If no -Interpreter was passed, see if it looks like a script
            if ($in -is [ScriptBlock] -or # If $in was a scriptblock
                $in -is [Management.Automation.ExternalScriptInfo] -or # or an external script
                $myInv.Line -match ' -ScriptBlock' # or it looks like the -ScriptBlock alias was used
            ) {
                $Interpreter = '/bin/pwsh' # assume PowerShell.
            } else {                
                $Interpreter = '/bin/sh'   # Otherwise, assume bash.
            }
        }

        # If we're making a Shebang for a function
        if ($in -is [Management.Automation.FunctionInfo] -or 
            $in -is [Management.Automation.FilterInfo] -or
            $in -is [Management.Automation.CmdletInfo]
        ) { 
            if (-not $PSBoundParameters['Interpreter']) {   # set the interpreter to PowerShell if we haven't already.
                $Interpreter = '/bin/pwsh'
            }
            if ($in.ModuleName -ne 'Microsoft.PowerShell.Core' -and $in.Module.Path) { # If the function came from a module.
                # recursively determine the import paths
                filter importPaths {
                    $module = $_
                    foreach ($req in $module.RequiredModules) { $req | importPaths }
                    if ($module.Path) {
                        $reqParentPath = $module.Path | Split-Path
                        if ($reqParentPath -match '\d.\d$') {
                            $reqParentPath | Split-Path
                        } elseif ($($reqParentPath | Split-Path -Leaf) -like "*$($module.Name)"){
                            $reqParentPath
                        } else {
                            $module.Path
                        }
                    }
                }

                # then import the module the function comes from and call it with the arguments
                $script = "
Import-Module '$(@($in.Module | importPaths) -join "','")'
$($in.Name) @args 
"
            } elseif (
                $in -is [Management.Automation.FunctionInfo] -or
                $in -is [Management.Automation.FilterInfo]
            ) {
                # If the function did not come from a module, wrap the command
                $script = "function $($in.Name) {
$Script
}
$($in.Name) @args
"
            } elseif ($in -is [Management.Automation.CommandInfo]) {
                $script = "$($in.Name) @args"
            }
        }

        # Shebangs are actually pretty simple.
        # The first line tells which interpreter should be used.
        $Interpreter = $Interpreter -replace '^\#\!'
        $newShebang = "#!$Interpreter" + [Environment]::NewLine + $Script # After the, the script is placed inline.
        #region Generate the Shebang Content
        #region Create the Shebang
        if ($WhatIfPreference) { # If -WhatIf was passed
            return $newShebang   # return the Shebang script.
        }

        if (-not $outputPath) { return $newShebang }
        
        Set-Content -Path $OutputPath -Value $newShebang # Otherwise, Set-Content
        
        # Last but not least, we need to make this file executable.
        # Assuming we're on linux, we'll have the command chmod to do this for us.
        $chmod = $ExecutionContext.SessionState.InvokeCommand.GetCommand('chmod','Application')
        if (-not $chmod) { return } # If we couldn't find chmod, return.
        & $chmod +x $OutputPath     # If we could, set the file to be executable with +x.
        #endregion Create the Shebang
    }
}