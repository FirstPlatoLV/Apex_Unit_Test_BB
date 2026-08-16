#!/usr/bin/env bash
set -euo pipefail
sf apex run test --target-org "${1:?usage: scripts/run-demo-tests.sh TARGET_ORG}" --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests QuoteToOrderDAOTest --tests DMLExecutorTest --tests BrownbagDemoPolicyTest --tests QuoteToOrderServiceFactoryTest --tests QuoteToOrderResultTest --tests SystemDateProviderTest --tests QuoteToOrderFacadeTest --synchronous --result-format human --code-coverage
