# Benchmark summary

- Org alias: `<ORG_ALIAS>`
- Date: 2026-08-16
- API version: 67.0
- Runs: one warm-up plus five measured runs per suite, synchronous and sequential
- Parallel Apex testing: org preference not exposed through the available Tooling API; measured suites themselves did not run in parallel.
- Legacy suite: 1 class, 2 methods; Salesforce median **1218 ms** (range 776–1427); wall median **3481 ms** (range 3451–6488).
- Mock suite: 1 class, 7 methods; Salesforce median **358 ms** (range 198–390); wall median **2456 ms** (range 2444–7492).

Execution time varies with org load and automation. These observations do not promise a fixed speedup ratio. Raw Salesforce CLI JSON is in `raw/`.
