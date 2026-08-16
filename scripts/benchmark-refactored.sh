#!/usr/bin/env bash
set -euo pipefail

target_org="${1:?usage: scripts/benchmark-refactored.sh TARGET_ORG [RUNS]}"
runs="${2:-5}"
command -v jq >/dev/null || { echo 'jq is required.' >&2; exit 1; }

timestamp="$(date +%Y%m%d-%H%M%S)"
results_dir="$(dirname "$0")/../benchmark-results/refactored-$timestamp"
raw_dir="$results_dir/raw"
mkdir -p "$raw_dir"
classes=(QuoteToOrderServiceTest QuoteToOrderDAOTest SystemDateProviderTest QuoteConversionPolicyTest)
test_args=()
for class_name in "${classes[@]}"; do
  test_args+=(--tests "$class_name")
done

echo 'suite,run,test_classes,test_methods,salesforce_ms,wall_ms' >"$results_dir/summary.csv"
for run in $(seq 0 "$runs"); do
  label="run-$run"
  [[ "$run" == 0 ]] && label='warmup'
  start_ms=$(date +%s%3N)
  sf apex run test --target-org "$target_org" "${test_args[@]}" --wait 30 --result-format json >"$raw_dir/$label.json"
  wall_ms=$(( $(date +%s%3N) - start_ms ))
  if [[ "$run" != 0 ]]; then
    methods=$(jq -r '.result.summary.testsRan' "$raw_dir/$label.json")
    salesforce_ms=$(jq -r '.result.summary.testExecutionTime' "$raw_dir/$label.json" | tr -dc '0-9')
    echo "refactored,$run,${#classes[@]},$methods,$salesforce_ms,$wall_ms" >>"$results_dir/summary.csv"
  fi
done

echo "Results written to $results_dir"
