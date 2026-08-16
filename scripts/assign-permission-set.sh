#!/usr/bin/env bash
set -euo pipefail
sf org assign permset --name Quote_Conversion --target-org "${1:?usage: scripts/assign-permission-set.sh TARGET_ORG}"
