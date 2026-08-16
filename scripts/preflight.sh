#!/usr/bin/env bash
set -euo pipefail
target_org="${1:?usage: scripts/preflight.sh TARGET_ORG}"
sf --version
sf org display --target-org "$target_org"
for object_name in Account Opportunity Product2 Pricebook2 PricebookEntry Quote QuoteLineItem Order OrderItem; do
  if ! sf sobject describe --sobject "$object_name" --target-org "$target_org" --json >/tmp/bb-describe.json; then
    echo "$object_name unavailable. Enable standard Quotes in Setup > Quote Settings or Orders in Setup > Order Settings; do not create substitutes." >&2
    exit 1
  fi
  echo "OK $object_name"
done
sf sobject describe --sobject Quote --target-org "$target_org" --json | grep -q '"value": "Accepted"' || { echo 'Accepted Quote status is not active.' >&2; exit 1; }
sf data query --target-org "$target_org" --use-tooling-api --query "SELECT SubscriberPackage.Name FROM InstalledSubscriberPackage WHERE SubscriberPackage.Name = 'Apex Mockery'" --json | grep -q 'Apex Mockery' || { echo 'Apex Mockery is not installed.' >&2; exit 1; }
