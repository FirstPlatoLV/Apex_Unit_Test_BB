param([Parameter(Mandatory=$true)][string]$TargetOrg)
& "$PSScriptRoot/preflight.ps1" $TargetOrg
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
sf project deploy start --target-org $TargetOrg --source-dir force-app/main/default --test-level RunSpecifiedTests --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests QuoteToOrderDAOTest --tests DMLExecutorTest --tests LegacyQuoteConversionPolicyTest --tests QuoteConversionPolicyTest --tests QuoteTriggerHandlerTest --tests QuoteTriggerTest --tests QuoteToOrderServiceFactoryTest --tests QuoteToOrderExceptionTest --tests QuoteToOrderResultTest --tests SystemDateProviderTest --tests TestUtilityTest --wait 30
