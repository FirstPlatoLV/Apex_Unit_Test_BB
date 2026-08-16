#!/usr/bin/env bash
set -euo pipefail
sf apex run test --target-org "${1:?usage: scripts/run-demo-tests.sh TARGET_ORG}" --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests QuoteToOrderDAOTest --tests DMLExecutorTest --tests LegacyQuoteConversionPolicyTest --tests QuoteConversionPolicyTest --tests QuoteTriggerDependenciesTest --tests QuoteTriggerHandlerTest --tests QuoteTriggerTest --tests QuoteToOrderExceptionTest --tests QuoteToOrderResultTest --tests SystemDateProviderTest --tests TestUtilityTest --wait 30 --result-format human --code-coverage
