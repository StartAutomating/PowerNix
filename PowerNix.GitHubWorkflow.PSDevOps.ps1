#requires -Module PSDevOps
Push-Location $PSScriptRoot


$workflowPath = Join-Path $PSScriptRoot .github |
    Join-Path -ChildPath workflows |
    Join-Path -ChildPath PowerNix.yml

New-GitHubWorkflow -Name PowerNix -Job PowerShellStaticAnalysis, TestPowerShellOnLinux -On Push |
    Set-Content $workflowPath -Encoding UTF8

Pop-Location
