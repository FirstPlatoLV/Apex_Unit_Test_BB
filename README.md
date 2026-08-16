# Testable Apex brown-bag demo

This Salesforce DX project contrasts a tightly coupled Quote-to-Order implementation with an interface-driven, constructor-injected service tested using Apex Mockery. It teaches the boundary between fast business-unit tests and focused Salesforce integration tests without claiming a universal performance ratio.

## Architecture

`LegacyQuoteToOrderService` contains mapping, the system clock, and static entry points, and calls concrete methods on `LegacyQuoteToOrderDAO` and the static `LegacyQuoteConversionPolicy`. The refactored path mirrors that shape with injectable `IQuoteToOrderDAO`, `IDateProvider`, and `IQuoteConversionPolicy` dependencies, while `QuoteToOrderService` implements `IQuoteToOrderService` for trigger injection. Both services expose the same bulk-only `Map<Id, QuoteToOrderResult> convert(Set<Id>)` contract and silently skip Quotes that are not in the configured status. `QuoteConversionPolicy` is a thin instance adapter that delegates to `LegacyQuoteConversionPolicy`, allowing service tests to mock the accepted status while the existing static implementation remains the production source of truth. `QuoteTrigger` delegates every context to `QuoteTriggerHandler`; the handler forwards status transitions to its injected service, and the service applies conversion policy. The new service owns rules and mapping, its DAO owns persistence orchestration, and an injected `IDMLExecutor` isolates the actual `Database` calls. `QuoteToOrderServiceFactory` composes the production dependencies.

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

The default Custom Metadata record accepts Quote status `Accepted`. Change `force-app/main/default/customMetadata/Quote_Conversion_Policy.Default.md-meta.xml` if preflight reports a different active business status.

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
sf project deploy start --target-org unittestorg --source-dir force-app/main/default --test-level RunSpecifiedTests --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests QuoteToOrderDAOTest --tests DMLExecutorTest --tests LegacyQuoteConversionPolicyTest --tests QuoteConversionPolicyTest --tests QuoteTriggerHandlerTest --tests QuoteTriggerTest --tests QuoteToOrderServiceFactoryTest --tests QuoteToOrderExceptionTest --tests QuoteToOrderResultTest --tests SystemDateProviderTest --tests TestUtilityTest --wait 30
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
- `QuoteToOrderServiceFactory`: production composition root.
- `LegacyQuoteConversionPolicy`: static access to the `Default` Custom Metadata configuration, used directly by the legacy service.
- `QuoteConversionPolicy`: injectable adapter that delegates to `LegacyQuoteConversionPolicy` through `IQuoteConversionPolicy`.
- `QuoteTriggerHandler` / `QuoteTriggerHandlerTest`: context routing and transition filtering tested with a mocked `IQuoteToOrderService`.
- `QuoteTrigger` / `QuoteTriggerTest`: thin trigger wiring with bulk integration coverage.

The benchmark runs each suite once for warm-up and five measured times, sequentially and synchronously. It saves every raw CLI JSON response plus `summary.csv` and `summary.md`. Results vary with org load and automation.

## Live presentation

Follow [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md): legacy service/test, baseline timing, interfaces/injected constructor, factory composition, mock happy path, mock failure path, timing comparison, then retained integration tests.

## Limitations and cleanup

This excludes CPQ/Revenue Cloud, UI, Flow, multi-currency, tax/discount logic, and quote synchronization. Tests create transactional records that Salesforce rolls back automatically. No persistent demo business records are created, so no record cleanup is required. Removing deployed metadata is intentionally not scripted; use a reviewed metadata-deletion process if needed. Apex Mockery is never modified by this project.
