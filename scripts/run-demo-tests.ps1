param([Parameter(Mandatory=$true)][string]$TargetOrg)
sf apex run test --target-org $TargetOrg --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests QuoteToOrderDAOTest --tests QuoteToOrderFacadeTest --synchronous --result-format human --code-coverage
