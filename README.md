# Testable Apex brown-bag demo

This Salesforce DX project contrasts a tightly coupled Quote-to-Order implementation with an interface-driven, constructor-injected service tested using Apex Mockery. It teaches the boundary between fast business-unit tests and focused Salesforce integration tests without claiming a universal performance ratio.

## Architecture

`LegacyQuoteToOrderService` contains mapping, the system clock, and static entry points, and calls concrete methods on `LegacyQuoteToOrderDAO` and the static `LegacyQuoteConversionPolicy`. As a transitional step, the same class implements `IQuoteToOrderService`; its instance method delegates directly to the existing static implementation while all legacy dependencies remain hardwired. The refactored path uses injectable `IQuoteToOrderDAO`, `IDateProvider`, and `IQuoteConversionPolicy` dependencies and implements `IQuoteToOrderService` directly. Both paths expose the same bulk result contract and silently skip Quotes that are not in the configured status. `QuoteConversionPolicy` is a thin instance adapter that delegates to `LegacyQuoteConversionPolicy`, while the existing static implementation remains the production source of truth. `QuoteTrigger` reads `Use_Legacy_Implementation__c`, selects one `IQuoteToOrderService` implementation, and passes that single dependency to `QuoteTriggerHandler`. `QuoteTriggerDependencies` composes the real production implementations. The end-to-end trigger tests use the actual Custom Metadata record, so changing the flag manually exercises the same assertions through the other implementation. The new service owns rules and mapping, its DAO owns persistence orchestration, and an injected `IDMLExecutor` isolates the actual `Database` calls.

All production classes use `inherited sharing`: callers determine record-sharing behavior, while the permission set grants explicit CRUD/FLS for manual demonstration. This sample is intentionally not a production-grade security framework.

## Prerequisites and preflight

- Salesforce CLI and an authenticated target org.
- Standard Quotes enabled at Setup → Quote Settings. Keep “Create Quotes Without a Related Opportunity” disabled.
- Standard Orders enabled at Setup → Order Settings.
- Apex Mockery pinned to installed package version **2.3.0.1** (package version ID `04tDn0000011O0VIAU`, API 61.0).

If Quote/QuoteLineItem is absent, enable Quotes; if Order/OrderItem is absent, enable Orders. Feature enablement is an org-level Setup action, separate from deployment. Never create custom substitutes.

```powershell
.\scripts\preflight.ps1 unittestorg
```

```bash
./scripts/preflight.sh unittestorg
```

The default Custom Metadata record accepts Quote status `Accepted` and sets `Use_Legacy_Implementation__c` to `false`. The policy API returns the complete record so callers can retrieve both values with one lookup. Change `force-app/main/default/customMetadata/Quote_Conversion_Policy.Default.md-meta.xml` if preflight reports a different active business status.

Apex Stub API mocks cannot cross a managed-package namespace boundary. This verified org and Apex Mockery install are both unnamespaced, so the limitation does not apply; revisit the packaging strategy in a namespaced org.

## Deploy and test

```powershell
.\scripts\deploy.ps1 unittestorg
.\scripts\assign-permission-set.ps1 unittestorg
.\scripts\run-demo-tests.ps1 unittestorg
.\scripts\benchmark-tests.ps1 unittestorg
```

Bash equivalents with the same filenames are also provided. Manual commands:

```text
sf project deploy start --target-org unittestorg --source-dir force-app/main/default --test-level RunSpecifiedTests --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests QuoteToOrderDAOTest --tests DMLExecutorTest --tests LegacyQuoteConversionPolicyTest --tests QuoteConversionPolicyTest --tests QuoteTriggerDependenciesTest --tests QuoteTriggerHandlerTest --tests QuoteTriggerTest --tests QuoteToOrderExceptionTest --tests QuoteToOrderResultTest --tests SystemDateProviderTest --tests TestUtilityTest --wait 30
sf org assign permset --name Quote_Conversion --target-org unittestorg
sf apex run test --target-org unittestorg --tests LegacyQuoteToOrderServiceTest --synchronous --result-format json
sf apex run test --target-org unittestorg --tests QuoteToOrderServiceTest --synchronous --result-format json
sf org open --target-org unittestorg
```

## Class and test map

Refactored-path tests use a method-oriented convention: each production method, including private methods exercised through public behavior, has a dedicated `<methodName>Test` method. One test covers all overloads sharing the same production method name.

- `LegacyQuoteToOrderService` / `LegacyQuoteToOrderDAO` / `LegacyQuoteToOrderServiceTest`: bulk-safe static coupling through set-based query/DML wrappers and complete persisted data graphs.
- `QuoteToOrderService` / `QuoteToOrderServiceTest`: injected business logic with method-oriented Mockery tests and no SOQL/DML.
- `QuoteToOrderDAO` / `QuoteToOrderDAOTest`: combined, bulk persistence behavior with mapping tested independently through a mocked `IDMLExecutor`.
- `DMLExecutor`: a reusable, object-agnostic wrapper around bulk insert, upsert, update, delete, and undelete `Database` calls, including `allOrNone`, external-ID, and access-level parameters.
- `QuoteTriggerDependencies`: production composition root for the policy and both service implementations.
- `LegacyQuoteConversionPolicy`: static access to the complete `Default` Custom Metadata policy record, used directly by the legacy service.
- `QuoteConversionPolicy`: injectable adapter that delegates the complete policy lookup to `LegacyQuoteConversionPolicy` through `IQuoteConversionPolicy`.
- `QuoteTrigger` / `QuoteTriggerTest`: positive and negative end-to-end conversion tests using the real metadata-controlled implementation selection.
- `QuoteTriggerHandler` / `QuoteTriggerHandlerTest`: context routing and transition filtering tested with one mocked service abstraction.

## Benchmark results

Before timing, the implementation-specific production classes were verified at 100% line coverage on both paths. Every production method is exercised. The legacy DAO is covered through the data-heavy service tests because its static coupling provides no useful isolated test seam. The refactored DAO verifies query execution through governor limits and verifies persistence mapping through a mocked `IDMLExecutor`.

The benchmark excludes `QuoteTriggerTest`, the reusable `DMLExecutorTest`, and shared trigger/result/utility tests that cannot be attributed uniquely to either implementation. The measured suites are:

- Legacy: `LegacyQuoteToOrderServiceTest` and `LegacyQuoteConversionPolicyTest`—2 classes and 12 test methods.
- Refactored: `QuoteToOrderServiceTest`, `QuoteToOrderDAOTest`, `SystemDateProviderTest`, and `QuoteConversionPolicyTest`—4 classes and 11 test methods.

Each suite ran once for warm-up followed by five measured runs. Suites alternated sequentially without parallel execution. Salesforce execution time is the platform-reported Apex test duration; wall time additionally includes CLI startup, network latency, queueing, and result processing.

| Suite      | Salesforce median | Salesforce range | Wall median |      Wall range |
| ---------- | ----------------: | ---------------: | ----------: | --------------: |
| Legacy     |          7,646 ms |   5,006–9,294 ms |   12,553 ms | 8,523–16,572 ms |
| Refactored |            291 ms |       260–484 ms |    4,477 ms |  3,472–8,530 ms |

In these measurements, the refactored suite used 96.2% less Salesforce execution time and had a 26.3× lower median. Its median wall time was 64.3% lower. Results vary with org load and automation and do not promise a universal speedup ratio.

The saved [benchmark summary](benchmark-results/implementation-20260816-200347/summary.md), [CSV measurements](benchmark-results/implementation-20260816-200347/summary.csv), and [raw CLI JSON](benchmark-results/implementation-20260816-200347/raw/) preserve the underlying results.

### DML executor infrastructure timing

`DMLExecutorTest` verifies the generic `Database` wrapper across insert, update, upsert, delete, and undelete operations. It is reusable infrastructure rather than a test suite that grows with each service, so its runtime is measured separately and does not count toward either service-suite result above.

After one warm-up, five measured synchronous runs produced:

| Run | Salesforce execution | Wall time |
| --: | -------------------: | --------: |
|   1 |             1,411 ms |  3,474 ms |
|   2 |               977 ms |  3,464 ms |
|   3 |             1,814 ms |  4,492 ms |
|   4 |             1,307 ms |  3,472 ms |
|   5 |               937 ms |  3,472 ms |

The Salesforce median was **1,307 ms** with a **937–1,814 ms** range. Median wall time was **3,472 ms** with a **3,464–4,492 ms** range. These measurements describe the one-time regression cost of the shared DML abstraction; they are not added to the refactored service timing.

The saved [DML executor summary](benchmark-results/dml-executor-20260816-201011/summary.md), [CSV measurements](benchmark-results/dml-executor-20260816-201011/summary.csv), and [raw CLI JSON](benchmark-results/dml-executor-20260816-201011/raw/) preserve the infrastructure benchmark.

### Legacy end-to-end timing

For this measurement, `Use_Legacy_Implementation__c` was manually enabled in the org. `QuoteTriggerTest` used the actual Custom Metadata record and production dependencies; it did not mock or override the policy, trigger handler, legacy service, DAO, or DML. The two methods cover successful Quote conversion and rejection of a non-eligible status.

After one warm-up, five measured synchronous runs produced the following per-method results:

| Run | `quoteTriggerTest` | `nonEligibleStatusTest` | Suite Salesforce | Wall time |
| --: | -----------------: | ----------------------: | ---------------: | --------: |
|   1 |           1,092 ms |                  570 ms |         1,676 ms |  4,463 ms |
|   2 |           1,288 ms |                  730 ms |         2,043 ms |  4,500 ms |
|   3 |             584 ms |                  458 ms |         1,051 ms |  3,486 ms |
|   4 |             617 ms |                  460 ms |         1,085 ms |  3,450 ms |
|   5 |             585 ms |                  355 ms |           951 ms |  3,464 ms |

Per-method findings:

- `quoteTriggerTest`, which performs the successful Quote-to-Order conversion: median **617 ms**, range **584–1,288 ms**.
- `nonEligibleStatusTest`, which verifies that an ineligible status creates no Order: median **460 ms**, range **355–730 ms**.
- Complete E2E suite: Salesforce median **1,085 ms**, range **951–2,043 ms**.
- Wall time: median **3,486 ms**, range **3,450–4,500 ms**.

This E2E timing is reported separately from the service-suite benchmark because it measures the entire trigger, metadata, query, mapping, and persistence path.

The saved [detailed legacy E2E summary](benchmark-results/e2e-legacy-detailed-20260816-201339/summary.md), [suite CSV](benchmark-results/e2e-legacy-detailed-20260816-201339/suite-summary.csv), [per-method CSV](benchmark-results/e2e-legacy-detailed-20260816-201339/method-summary.csv), and [raw CLI JSON](benchmark-results/e2e-legacy-detailed-20260816-201339/raw/) preserve the end-to-end benchmark.

### Refactored end-to-end timing

For this measurement, `Use_Legacy_Implementation__c` was manually disabled in the org. The same unmodified `QuoteTriggerTest` methods used the actual Custom Metadata record and the fully composed refactored service, DAO, DML executor, policy, and date provider.

After one warm-up, five measured synchronous runs produced:

| Run | `quoteTriggerTest` | `nonEligibleStatusTest` | Suite Salesforce | Wall time |
| --: | -----------------: | ----------------------: | ---------------: | --------: |
|   1 |           1,380 ms |                  693 ms |         2,086 ms |  4,475 ms |
|   2 |             572 ms |                  424 ms |         1,002 ms |  3,474 ms |
|   3 |           1,031 ms |                  660 ms |         1,706 ms |  4,481 ms |
|   4 |             595 ms |                  442 ms |         1,047 ms |  3,501 ms |
|   5 |           1,183 ms |                  702 ms |         1,899 ms |  7,507 ms |

Per-method findings:

- `quoteTriggerTest`: median **1,031 ms**, range **572–1,380 ms**.
- `nonEligibleStatusTest`: median **660 ms**, range **424–702 ms**.
- Complete E2E suite: Salesforce median **1,706 ms**, range **1,002–2,086 ms**.
- Wall time: median **4,475 ms**, range **3,474–7,507 ms**.

The saved [detailed refactored E2E summary](benchmark-results/e2e-refactored-detailed-20260816-201637/summary.md), [suite CSV](benchmark-results/e2e-refactored-detailed-20260816-201637/suite-summary.csv), [per-method CSV](benchmark-results/e2e-refactored-detailed-20260816-201637/method-summary.csv), and [raw CLI JSON](benchmark-results/e2e-refactored-detailed-20260816-201637/raw/) preserve the refactored end-to-end benchmark.

### End-to-end comparison

| Measurement             | Legacy median | Refactored median |
| ----------------------- | ------------: | ----------------: |
| `quoteTriggerTest`      |        617 ms |          1,031 ms |
| `nonEligibleStatusTest` |        460 ms |            660 ms |
| Complete Salesforce run |      1,085 ms |          1,706 ms |
| Wall time               |      3,486 ms |          4,475 ms |

In these five-run samples, the refactored E2E median was higher. The ranges overlap substantially, and both paths perform the same real setup, SOQL, Order/OrderItem DML, Quote update, and trigger execution. This comparison validates equivalent production behavior; it does not isolate the unit-test speed benefit measured in the implementation benchmark above.

### Reproducing the E2E measurement

Set `Use_Legacy_Implementation__c` on the org's `Quote_Conversion_Policy.Default` Custom Metadata record to the implementation being measured. `QuoteTriggerTest` reads the real record, so no test-code change is required. Run one unmeasured warm-up, then five measured runs. Keep the runs sequential and do not enable parallel execution.

Single run, including the per-method runtime breakdown:

```text
sf apex run test --target-org unittestorg --tests QuoteTriggerTest --synchronous --result-format human --code-coverage
```

PowerShell warm-up and five measured JSON runs:

```powershell
sf apex run test --target-org unittestorg --tests QuoteTriggerTest --synchronous --result-format json | Out-Null

1..5 | ForEach-Object {
    sf apex run test --target-org unittestorg --tests QuoteTriggerTest --synchronous --result-format json |
        Set-Content -Encoding utf8 "quote-trigger-run-$_.json"
}
```

Bash warm-up and five measured JSON runs:

```bash
sf apex run test --target-org unittestorg --tests QuoteTriggerTest --synchronous --result-format json >/dev/null

for run in 1 2 3 4 5; do
  sf apex run test --target-org unittestorg --tests QuoteTriggerTest --synchronous --result-format json \
    >"quote-trigger-run-${run}.json"
done
```

In each JSON file, use `result.tests[].MethodName` and `result.tests[].RunTime` for the per-method measurements and `result.summary.testExecutionTime` for the complete Salesforce test execution time. Measure the CLI process externally when wall-clock time is also required.

## Live presentation

Follow [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md): legacy service/test, baseline timing, interfaces/injected constructor, factory composition, mock happy path, mock failure path, timing comparison, then retained integration tests.

## Limitations and cleanup

This excludes CPQ/Revenue Cloud, UI, Flow, multi-currency, tax/discount logic, and quote synchronization. Tests create transactional records that Salesforce rolls back automatically. No persistent demo business records are created, so no record cleanup is required. Removing deployed metadata is intentionally not scripted; use a reviewed metadata-deletion process if needed. Apex Mockery is never modified by this project.
