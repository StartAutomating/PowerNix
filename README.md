# Linux for PowerShell People

Linux often involves a lot of tools and a lot of parsing.  
This can be challenging for PowerShell People, because most of PowerShell works with objects.


PowerNix is a new PowerShell module that hopes to make Linux easier to use by providing a more PowerShell-centric experience.

If this sounds like something you'd like, consider [contributing](contributing.md).

### Exposing Linux Functionality to PowerShell

What makes a _good_ PowerShell module?

A good PowerShell module will have easy to understand commands that output objects.
Those objects will often be formatted by PowerShell to make them more useful.

The goal of PowerNix is to expose Linux functionality in a _good_ PowerShell module.

### Commands for Common Linux Scenarios

To start off with, PowerNix has a few commands for getting system statistics and manipulating mounts.

----------------------
|  Verb | Noun        |
| ----: | :-----------|
|   Get | -NixLog     |
|       | -NixMemory  |
|       | -NixMount   |
|       | -NixUptime  |
|       | -NixDistro  |
|       | -NixComputer|
| Mount | -Nix        |
----------------------

#### Want to help out? [Contribute](contributing.md)
