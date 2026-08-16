#!/usr/bin/env bash
set -euo pipefail
target_org="${1:?usage: scripts/deploy.sh TARGET_ORG}"
"$(dirname "$0")/preflight.sh" "$target_org"
sf project deploy start --target-org "$target_org" --source-dir force-app/main/default --test-level RunSpecifiedTests --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests QuoteToOrderDAOTest --tests DMLExecutorTest --tests LegacyQuoteConversionPolicyTest --tests QuoteConversionPolicyTest --tests QuoteToOrderServiceFactoryTest --tests QuoteToOrderResultTest --tests SystemDateProviderTest --tests TestUtilityTest --tests QuoteToOrderFacadeTest --wait 30
