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
@'
Aug 24 00:06:07 ubuntu rsyslogd: [origin software="rsyslogd" swVersion="8.2001.0" x-pid="699" x-info="https://www.rsyslog.com"] rsyslogd was HUPed
Aug 24 00:06:07 ubuntu NetworkManager[690]: <info>  [1629763567.4088] NetworkManager (version 1.22.10) is starting... (for the first time)
Aug 24 00:06:07 ubuntu systemd[1]: Started Network Manager.
Aug 24 00:00:01 linux-test systemd[1]: logrotate.service: Succeeded.
Aug 24 00:00:01 linux_test systemd[1]: logrotate.service: Succeeded.
Sep  7 15:57:24 ubuntu systemd[980]: Reached target Main User Target.
Sep  7 15:57:24 ubuntu systemd[980]: Startup finished in 510ms.
'@ | Set-Content '/tmp/test-syslog'
            $FileLogs = Get-NixLog -LogFilePath '/tmp/test-syslog'
        }
        AfterAll{
            Remove-Item -Path '/tmp/test-syslog' -Force
        }
        It 'Should get logs from /var/log/test-syslog' {
            $FileLogs | Should -not -be $null
        }
        It 'Should have a message from syslog' {
            $Message = $FileLogs | Select-Object -First 1 -Property Message
            $Message | Should -not -be $null
        }
        It 'Should get Kernel Logs' {
            $KernelLogs = Get-NixLog -KernalOnly -LineNumber 1
            $KernelLogs.SYSLOG_IDENTIFIER | Should -Be 'kernel'
        } -skip #because "systemd not present in container"
        It 'Should get a journald log for PowerShell' {
            $JournalctlLogs = Get-NixLog -Identifier powershell -LineNumber 1 -After "2021-06-21 11:00:00"
            $JournalctlLogs.SYSLOG_IDENTIFIER | Should -be 'powershell'
        } -skip #because "systemd not present in container"
    }
    it 'Can Get Uptimes' {
        $uptime = Get-NixUptime
        $uptime.Uptime | Should -BeGreaterThan ([Timespan]"00:00:01")
    }

    it 'Can Get Memory' {
        $memInfo =  Get-NixMemory
        $memInfo.MemoryPercentFree | Should -BeLessOrEqual 100
    }

    it 'Can Output Shebangs' {
        Out-Shebang -Script "$({ "hello world $args" })" -Interpreter /bin/pwsh | 
            Should -BeLike '#!/bin/pwsh*hello*world*$args*'
    }        
}