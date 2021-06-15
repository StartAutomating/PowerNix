#requires -Module PSDevOps
Push-Location $PSScriptRoot


$workflowPath = Join-Path $PSScriptRoot .github |
    Join-Path -ChildPath workflows |
    Join-Path -ChildPath PowerNix.yml

New-GitHubWorkflow -On Push, PullToMain, Demand -Name PowerNix -Job PowerShellStaticAnalysis, TestPowerShellOnLinux, UpdateModuleTag, PublishToGallery  |
    Set-Content $workflowPath -Encoding UTF8 -PassThru

Pop-Location
