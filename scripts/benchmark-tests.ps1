param(
    [Parameter(Mandatory = $true)][string]$TargetOrg,
    [int]$Runs = 5
)

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'benchmark-legacy.ps1') $TargetOrg $Runs
& (Join-Path $PSScriptRoot 'benchmark-refactored.ps1') $TargetOrg $Runs
