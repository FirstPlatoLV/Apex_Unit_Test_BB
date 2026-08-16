param([Parameter(Mandatory=$true)][string]$TargetOrg)
$ErrorActionPreference = 'Stop'
sf --version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
sf org display --target-org $TargetOrg
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$required = @('Account','Opportunity','Product2','Pricebook2','PricebookEntry','Quote','QuoteLineItem','Order','OrderItem')
foreach ($name in $required) {
    $raw = sf sobject describe --sobject $name --target-org $TargetOrg --json
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$name is unavailable. Enable standard Quotes in Setup > Quote Settings or Orders in Setup > Order Settings, then rerun preflight. Do not create substitute custom objects."
        exit 1
    }
    $description = $raw | ConvertFrom-Json
    Write-Host "OK $name (queryable=$($description.result.queryable), createable=$($description.result.createable))"
    if ($name -eq 'Quote') {
        $statuses = $description.result.fields | Where-Object name -eq 'Status' | Select-Object -ExpandProperty picklistValues | Where-Object active | Select-Object -ExpandProperty value
        if ($statuses -notcontains 'Accepted') { Write-Error "Quote status Accepted is not active. Change Quote_Conversion_Policy.Default before deployment."; exit 1 }
    }
}
$packages = sf data query --target-org $TargetOrg --use-tooling-api --query "SELECT SubscriberPackage.Name, SubscriberPackage.NamespacePrefix, SubscriberPackageVersion.MajorVersion, SubscriberPackageVersion.MinorVersion, SubscriberPackageVersion.PatchVersion, SubscriberPackageVersion.BuildNumber FROM InstalledSubscriberPackage WHERE SubscriberPackage.Name = 'Apex Mockery'" --json | ConvertFrom-Json
if ($packages.result.totalSize -ne 1) { Write-Error 'Apex Mockery is not installed.'; exit 1 }
$package = $packages.result.records[0]
Write-Host "OK Apex Mockery $($package.SubscriberPackageVersion.MajorVersion).$($package.SubscriberPackageVersion.MinorVersion).$($package.SubscriberPackageVersion.PatchVersion).$($package.SubscriberPackageVersion.BuildNumber), namespace=$($package.SubscriberPackage.NamespacePrefix)"
