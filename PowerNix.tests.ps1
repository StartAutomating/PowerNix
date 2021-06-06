﻿#requires -Module Pester, PowerNix
describe PowerNix {
    context Mounts {
        it 'Can Mount a Filesystem' {
            Mount-Nix -Device //computer/share/ -MountPoint /mnt/computer -FileSystemType cifs -Option rw -WhatIf |
                Should -Be 'mount -t cifs //computer/share/ /mnt/computer -o rw'
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
}