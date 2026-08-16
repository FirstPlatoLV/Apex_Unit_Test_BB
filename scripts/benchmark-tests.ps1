param([Parameter(Mandatory=$true)][string]$TargetOrg, [int]$Runs = 5)
$ErrorActionPreference = 'Stop'
$rawDir = Join-Path $PSScriptRoot '..\benchmark-results\raw'
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
$rows = @()
$suites = @(@{ Name='legacy'; Class='LegacyQuoteToOrderServiceTest' }, @{ Name='mock'; Class='QuoteToOrderServiceTest' })
foreach ($suite in $suites) {
    for ($run = 0; $run -le $Runs; $run++) {
        $label = if ($run -eq 0) { "$($suite.Name)-warmup" } else { "$($suite.Name)-$run" }
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $output = sf apex run test --target-org $TargetOrg --tests $suite.Class --synchronous --result-format json
        $exitCode = $LASTEXITCODE; $watch.Stop()
        $output | Set-Content -Encoding utf8 (Join-Path $rawDir "$label.json")
        if ($exitCode -ne 0) { throw "$label failed" }
        $json = $output | ConvertFrom-Json
        if ($run -gt 0) {
            $rows += [pscustomobject]@{ suite=$suite.Name; class=$suite.Class; run=$run; methods=$json.result.summary.testsRan; salesforce_ms=[int](($json.result.summary.testExecutionTime -replace '[^0-9]','')); wall_ms=$watch.ElapsedMilliseconds }
        }
    }
}
$resultsDir = Split-Path $rawDir
$rows | Export-Csv -NoTypeInformation (Join-Path $resultsDir 'summary.csv')
$lines = @('# Benchmark summary', '', "- Org alias: $TargetOrg", "- Date: $(Get-Date -Format yyyy-MM-dd)", '- API version: 65.0', '- One warm-up plus measured runs; suites synchronous and sequential.', '- Parallel Apex testing: record the org preference manually if available; measured suites do not run in parallel.', '')
foreach ($suiteName in @('legacy','mock')) {
    $values = $rows | Where-Object suite -eq $suiteName
    $sf = @($values.salesforce_ms | Sort-Object); $wall = @($values.wall_ms | Sort-Object); $middle = [math]::Floor($sf.Count / 2)
    $lines += "- ${suiteName}: 1 class, $($values[0].methods) methods; Salesforce median $($sf[$middle]) ms (range $($sf[0])-$($sf[-1])); wall median $($wall[$middle]) ms (range $($wall[0])-$($wall[-1]))."
}
$lines += ''; $lines += 'Execution time varies with org load and automation. No fixed speedup is implied.'
$lines | Set-Content -Encoding utf8 (Join-Path $resultsDir 'summary.md')
Get-Content (Join-Path $resultsDir 'summary.md')
