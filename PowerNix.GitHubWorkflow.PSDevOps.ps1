﻿#requires -Module PSDevOps
Push-Location $PSScriptRoot


$workflowPath = Join-Path $PSScriptRoot .github |
    Join-Path -ChildPath workflows |
    Join-Path -ChildPath PowerNix.yml

New-GitHubWorkflow -On Push -Name PowerNix -Job PowerShellStaticAnalysis, TestPowerShellOnLinux  |
    Set-Content $workflowPath -Encoding UTF8 -PassThru

Pop-Location
