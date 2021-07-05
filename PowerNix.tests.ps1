#requires -Module Pester, PowerNix
describe PowerNix {
    context Mounts {
        it 'Can Get-NixMount' {
            $nixMounts = Get-NixMount
            $nixMounts |
                Select-Object -ExpandProperty MountPoint |
                Should -BeLike '/*'
        }
        it 'Can Mount a Filesystem' {
            Mount-Nix -Device //computer/share/ -MountPoint /mnt/computer -FileSystemType cifs -Option rw -WhatIf |
                Should -Be 'mount -t cifs //computer/share/ /mnt/computer -o rw'
        }

        it 'Can Get Distro Information' {
            Get-NixDistro | Select-Object -ExpandProperty Name | Should -Belike *
        }

        it 'Can Mount a FileSystem that is -Persistent' {
            Mount-Nix -Device //computer/share/ -MountPoint /mnt/computer -FileSystemType cifs -Option rw -WhatIf -Persistent |
                Should -Be '//computer/share/ /mnt/computer cifs rw 0 0'
        }

        it 'Can Dismount by MountPoint' {
            Dismount-Nix -MountPoint //computer/share -WhatIf | Should -BeLike 'umount*//computer/share*'
        }

        it 'Can Dismount -All (and will warn you)' {
            $dismountOutput = Dismount-Nix -All -WhatIf *>&1
            $dismountOutput[0].GetType() | Should -Be ([Management.Automation.WarningRecord])
            $dismountOutput[1] | Should -Be 'umount -a'
        }
    }

    context Logs {
        BeforeAll  {
            $FileLogs = Get-NixLog -LogFilePath /var/log/syslog
            $KernelLogs = Get-NixLog -KernalOnly -LineNumber 1
            $JournalctlLogs = Get-NixLog -Identifier powershell -LineNumber 1 -After "2021-06-21 11:00:00"
            mock pidof {
                return $true
            }
        }
        It 'Should get logs from /var/log/syslog' {
            $FileLogs | Should -not -be $null
        }
        It 'Should have a syslog for PowerShell' {
            $PowerShellLog = $FileLogs | Where-Object { $psitem.Process -ieq 'Powershell' } | Select-Object -First 1
            $PowerShellLog | Should -not -be $null
        }
        It 'Should get Kernel Logs' {
            $KernelLogs.SYSLOG_IDENTIFIER | Should -Be 'kernel'
        }
        It 'Should get a journald log for PowerShell' {
            $JournalctlLogs.SYSLOG_IDENTIFIER | Should -be 'powershell'
        }
    }
    it 'Can Get Uptimes' {
        $uptime = Get-NixUptime
        $uptime.Uptime | Should -BeGreaterThan ([Timespan]"00:00:01")
    }

    it 'Can Get Memory' {
        $memInfo =  Get-NixMemory
        $memInfo.MemoryPercentFree | Should -BeLessOrEqual 100
    }
}