#!/usr/bin/env bash
set -euo pipefail
target_org="${1:?usage: scripts/benchmark-tests.sh TARGET_ORG [RUNS]}"; runs="${2:-5}"
command -v jq >/dev/null || { echo 'jq is required.' >&2; exit 1; }
raw_dir="$(dirname "$0")/../benchmark-results/raw"; mkdir -p "$raw_dir"
echo 'suite,class,run,methods,salesforce_ms,wall_ms' >"$(dirname "$raw_dir")/summary.csv"
for pair in 'legacy LegacyQuoteToOrderServiceTest' 'mock QuoteToOrderServiceTest'; do
  read -r suite class_name <<<"$pair"
  for run in $(seq 0 "$runs"); do
    label="$suite-$run"; [[ "$run" == 0 ]] && label="$suite-warmup"
    start_ms=$(date +%s%3N); sf apex run test --target-org "$target_org" --tests "$class_name" --synchronous --result-format json >"$raw_dir/$label.json"; wall_ms=$(( $(date +%s%3N) - start_ms ))
    [[ "$run" == 0 ]] || echo "$suite,$class_name,$run,$(jq -r '.result.summary.testsRan' "$raw_dir/$label.json"),$(jq -r '.result.summary.testExecutionTime' "$raw_dir/$label.json" | tr -dc '0-9'),$wall_ms" >>"$(dirname "$raw_dir")/summary.csv"
  done
done
echo 'Raw results and summary.csv written under benchmark-results.'
