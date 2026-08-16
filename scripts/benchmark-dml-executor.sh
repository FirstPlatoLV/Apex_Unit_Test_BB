#!/usr/bin/env bash
set -euo pipefail

target_org="${1:?usage: scripts/benchmark-dml-executor.sh TARGET_ORG [RUNS]}"
runs="${2:-5}"
command -v jq >/dev/null || { echo 'jq is required.' >&2; exit 1; }

timestamp="$(date +%Y%m%d-%H%M%S)"
results_dir="$(dirname "$0")/../benchmark-results/dml-executor-$timestamp"
raw_dir="$results_dir/raw"
mkdir -p "$raw_dir"
echo 'suite,run,test_classes,test_methods,test_setup_executions,tests_ran,salesforce_ms,wall_ms' >"$results_dir/summary.csv"

for run in $(seq 0 "$runs"); do
  label="run-$run"
  [[ "$run" == 0 ]] && label='warmup'
  start_ms=$(date +%s%3N)
  sf apex run test --target-org "$target_org" --tests DMLExecutorTest --synchronous --result-format json >"$raw_dir/$label.json"
  wall_ms=$(( $(date +%s%3N) - start_ms ))
  if [[ "$run" != 0 ]]; then
    methods=$(jq -r '.result.tests | length' "$raw_dir/$label.json")
    tests_ran=$(jq -r '.result.summary.testsRan' "$raw_dir/$label.json")
    setup_executions=$(( tests_ran - methods ))
    salesforce_ms=$(jq -r '.result.summary.testExecutionTime' "$raw_dir/$label.json" | tr -dc '0-9')
    echo "dml-executor,$run,1,$methods,$setup_executions,$tests_ran,$salesforce_ms,$wall_ms" >>"$results_dir/summary.csv"
  fi
done

echo "Results written to $results_dir"
