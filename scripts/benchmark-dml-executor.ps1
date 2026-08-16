param(
    [Parameter(Mandatory = $true)][string]$TargetOrg,
    [int]$Runs = 5
)

$ErrorActionPreference = 'Stop'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$resultsDir = Join-Path $PSScriptRoot "..\benchmark-results\dml-executor-$timestamp"
$rawDir = Join-Path $resultsDir 'raw'
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null

$rows = @()
for ($run = 0; $run -le $Runs; $run++) {
    $label = if ($run -eq 0) { 'warmup' } else { "run-$run" }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $output = & sf apex run test --target-org $TargetOrg --tests DMLExecutorTest --synchronous --result-format json
    $exitCode = $LASTEXITCODE
    $watch.Stop()
    $output | Set-Content -Encoding utf8 (Join-Path $rawDir "$label.json")
    if ($exitCode -ne 0) {
        throw "$label failed"
    }

    if ($run -gt 0) {
        $json = $output | ConvertFrom-Json
        $testMethods = @($json.result.tests).Count
        $testsRan = [int]$json.result.summary.testsRan
        $rows += [pscustomobject]@{
            suite = 'dml-executor'
            run = $run
            test_classes = 1
            test_methods = $testMethods
            test_setup_executions = $testsRan - $testMethods
            tests_ran = $testsRan
            salesforce_ms = [int](($json.result.summary.testExecutionTime -replace '[^0-9]', ''))
            wall_ms = $watch.ElapsedMilliseconds
        }
    }
}

$rows | Export-Csv -NoTypeInformation (Join-Path $resultsDir 'summary.csv')
$salesforceTimes = @($rows.salesforce_ms | Sort-Object)
$wallTimes = @($rows.wall_ms | Sort-Object)
$middle = [math]::Floor($rows.Count / 2)
$summary = @(
    '# DML executor infrastructure benchmark',
    '',
    "- Org alias: $TargetOrg",
    "- Date: $(Get-Date -Format yyyy-MM-dd)",
    '- API version: 65.0',
    '- Suite: DMLExecutorTest',
    "- One warm-up plus $Runs measured runs, submitted and completed sequentially.",
    "- DML executor: 1 class, $($rows[0].test_methods) methods, $($rows[0].test_setup_executions) @TestSetup executions, Salesforce testsRan $($rows[0].tests_ran); Salesforce median $($salesforceTimes[$middle]) ms (range $($salesforceTimes[0])-$($salesforceTimes[-1])); wall median $($wallTimes[$middle]) ms (range $($wallTimes[0])-$($wallTimes[-1]))."
)
$summary | Set-Content -Encoding utf8 (Join-Path $resultsDir 'summary.md')

Write-Output $resultsDir
Get-Content (Join-Path $resultsDir 'summary.md')
