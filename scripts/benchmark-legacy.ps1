param(
    [Parameter(Mandatory = $true)][string]$TargetOrg,
    [int]$Runs = 5
)

$ErrorActionPreference = 'Stop'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$resultsDir = Join-Path $PSScriptRoot "..\benchmark-results\legacy-$timestamp"
$rawDir = Join-Path $resultsDir 'raw'
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null

$classes = @(
    'LegacyQuoteToOrderServiceTest',
    'LegacyQuoteConversionPolicyTest'
)
$testArguments = @()
foreach ($className in $classes) {
    $testArguments += @('--tests', $className)
}

$rows = @()
for ($run = 0; $run -le $Runs; $run++) {
    $label = if ($run -eq 0) { 'warmup' } else { "run-$run" }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $output = & sf apex run test --target-org $TargetOrg @testArguments --wait 30 --result-format json
    $exitCode = $LASTEXITCODE
    $watch.Stop()
    $output | Set-Content -Encoding utf8 (Join-Path $rawDir "$label.json")
    if ($exitCode -ne 0) {
        throw "$label failed"
    }

    if ($run -gt 0) {
        $json = $output | ConvertFrom-Json
        $rows += [pscustomobject]@{
            suite = 'legacy'
            run = $run
            test_classes = $classes.Count
            # testsRan includes @TestSetup; the result list contains test methods.
            test_methods = @($json.result.tests).Count
            salesforce_ms = [int](($json.result.summary.testExecutionTime -replace '[^0-9]', ''))
            wall_ms = $watch.ElapsedMilliseconds
        }
    }
}

$summaryCsv = Join-Path $resultsDir 'summary.csv'
$rows | Export-Csv -NoTypeInformation $summaryCsv
$salesforceTimes = @($rows.salesforce_ms | Sort-Object)
$wallTimes = @($rows.wall_ms | Sort-Object)
$middle = [math]::Floor($rows.Count / 2)
$summary = @(
    '# Legacy implementation benchmark',
    '',
    "- Org alias: $TargetOrg",
    "- Date: $(Get-Date -Format yyyy-MM-dd)",
    '- API version: 65.0',
    "- Suite: $($classes -join ', ')",
    "- One warm-up plus $Runs measured runs, submitted and completed sequentially.",
    "- Legacy: $($classes.Count) classes, $($rows[0].test_methods) methods; Salesforce median $($salesforceTimes[$middle]) ms (range $($salesforceTimes[0])-$($salesforceTimes[-1])); wall median $($wallTimes[$middle]) ms (range $($wallTimes[0])-$($wallTimes[-1]))."
)
$summary | Set-Content -Encoding utf8 (Join-Path $resultsDir 'summary.md')

Write-Output $resultsDir
Get-Content (Join-Path $resultsDir 'summary.md')
