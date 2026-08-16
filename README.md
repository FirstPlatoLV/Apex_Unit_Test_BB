# Testable Apex brown-bag demo

This Salesforce DX project contrasts a tightly coupled Quote-to-Order implementation with an interface-driven, constructor-injected service tested using Apex Mockery. It teaches the boundary between fast business-unit tests and focused Salesforce integration tests without claiming a universal performance ratio.

## Architecture

`LegacyQuoteToOrderService` contains SOQL, mapping, DML, the system clock, and a static entry point. The refactored path separates `IQuoteRepository`, `IQuoteLineRepository`, `IOrderRepository`, and `IDateProvider`; `QuoteToOrderService` owns rules/mapping only; Salesforce implementations own persistence; `QuoteToOrderServiceFactory` composes production dependencies; and `QuoteToOrder` preserves a static caller API.

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

The default Custom Metadata record accepts Quote status `Accepted`. Change `force-app/main/default/customMetadata/Brownbag_Demo_Config.Default.md-meta.xml` if preflight reports a different active business status.

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
sf project deploy start --target-org unittestorg --source-dir force-app/main/default --test-level RunSpecifiedTests --tests LegacyQuoteToOrderServiceTest --tests QuoteToOrderServiceTest --tests SalesforceRepositoriesTest --tests QuoteToOrderFacadeTest --wait 30
sf org assign permset --name Brownbag_Testable_Apex --target-org unittestorg
sf apex run test --target-org unittestorg --tests LegacyQuoteToOrderServiceTest --synchronous --result-format json
sf apex run test --target-org unittestorg --tests QuoteToOrderServiceTest --synchronous --result-format json
sf org open --target-org unittestorg
```

## Class and test map

- `LegacyQuoteToOrderService` / `LegacyQuoteToOrderServiceTest`: coupled code and complete persisted data graph.
- `QuoteToOrderService` / `QuoteToOrderServiceTest`: injected business logic and seven Mockery tests with no SOQL/DML.
- `Salesforce*Repository` / `SalesforceRepositoriesTest`: focused Salesforce persistence behavior.
- `QuoteToOrderServiceFactory`: production composition root.
- `QuoteToOrder` / `QuoteToOrderFacadeTest`: static compatibility API and integration path.
- `BrownbagDemoPolicy`: reads the `Default` Custom Metadata configuration.

The benchmark runs each suite once for warm-up and five measured times, sequentially and synchronously. It saves every raw CLI JSON response plus `summary.csv` and `summary.md`. Results vary with org load and automation.

## Live presentation

Follow [DEMO_RUNBOOK.md](DEMO_RUNBOOK.md): legacy service/test, baseline timing, interfaces/injected constructor, factory/façade, mock happy path, mock failure path, timing comparison, then retained integration tests.

## Limitations and cleanup

This excludes CPQ/Revenue Cloud, UI, Flow, multi-currency, tax/discount logic, quote synchronization, and bulk conversion. Tests create transactional records that Salesforce rolls back automatically. No persistent demo business records are created, so no record cleanup is required. Removing deployed metadata is intentionally not scripted; use a reviewed metadata-deletion process if needed. Apex Mockery is never modified by this project.
