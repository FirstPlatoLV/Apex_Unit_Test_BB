#!/usr/bin/env bash
set -euo pipefail

target_org="${1:?usage: scripts/benchmark-tests.sh TARGET_ORG [RUNS]}"
runs="${2:-5}"
script_dir="$(cd "$(dirname "$0")" && pwd)"

"$script_dir/benchmark-legacy.sh" "$target_org" "$runs"
"$script_dir/benchmark-refactored.sh" "$target_org" "$runs"
