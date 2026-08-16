#!/usr/bin/env bash
set -euo pipefail
sf apex run test --target-org "${1:?usage: scripts/run-demo-tests.sh TARGET_ORG}" --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests QuoteToOrderDAOTest --tests DMLExecutorTest --tests LegacyQuoteConversionPolicyTest --tests QuoteConversionPolicyTest --tests QuoteTriggerHandlerTest --tests QuoteTriggerTest --tests QuoteToOrderServiceFactoryTest --tests QuoteToOrderExceptionTest --tests QuoteToOrderResultTest --tests SystemDateProviderTest --tests TestUtilityTest --synchronous --result-format human --code-coverage
