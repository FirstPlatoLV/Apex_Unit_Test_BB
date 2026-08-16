# Testable Apex Brownbag Demo — Implementation Specification

## 1. Purpose

Build a deployable Salesforce DX demonstration that compares two implementations of the same Quote-to-Order use case:

1. A deliberately naïve, tightly coupled implementation with database-backed tests.
2. A refactored implementation using interfaces, Dependency Inversion, constructor-based Dependency Injection, Inversion of Control, and mock-based unit tests using Salesforce Apex Mockery.

The demo must let a presenter show:

- why conventional Apex tests often become integration tests;
- the amount of Salesforce data required before the business rule can be exercised;
- how interfaces make dependencies substitutable;
- how Apex Mockery controls dependency behavior through the Apex Stub API;
- the difference between unit and integration tests;
- comparative test execution times measured in the same developer org;
- how the refactored design can coexist with static legacy callers.

This is teaching code. It must be small, readable, deterministic, and suitable for live explanation.

## 2. Environment assumptions

- A Salesforce Developer Edition org or developer sandbox is available.
- Salesforce CLI (`sf`) is installed and on `PATH`.
- The target org is authenticated and has an alias supplied by the user.
- Quotes and Orders may initially be disabled in the target org and must be checked during setup.
- Standard Price Books are available.
- Apex Mockery is installed or can be deployed as part of setup.
- The repository uses Salesforce DX source format.

Codex must not assume an org alias. All scripts must accept it through `--target-org`, a positional argument, or a clearly documented environment variable such as `BB_TARGET_ORG`.

## 3. Preflight requirements

Before deployment, provide a read-only preflight script that verifies:

- `sf --version` succeeds;
- the target org can be resolved;
- the authenticated user has access to Account, Opportunity, Order, OrderItem, Product2, Pricebook2, and PricebookEntry;
- whether the standard Quote and QuoteLineItem objects are available;
- whether Quotes and Orders are enabled;
- the standard Quote status value used by the demo is available;
- Apex Mockery classes are present, or the documented installation step is still required.

If Quote cannot be described, preflight must stop before deployment and print the feature-enablement instructions in section 3.1. It must not interpret the missing standard object as a request to deploy a custom `Quote__c` replacement.

If the org uses a different accepted Quote status value, deployment must support configuration rather than silently changing the business rule.

Default teaching value: `Accepted`.

### 3.1 Enable the standard Quotes feature

Quote and QuoteLineItem are Salesforce standard objects. They must not be recreated as custom objects.

If Quote is absent from the Developer Edition org, setup must include this manual prerequisite:

1. Open Salesforce Setup.
2. Enter `Quote` in Quick Find.
3. Select **Quote Settings**.
4. Select **Enable Quotes**.
5. Keep **Create Quotes Without a Related Opportunity** disabled for this demo, because the use case intentionally follows Opportunity → Quote → Order.
6. Save.
7. If Salesforce offers to add the Quotes related list to Opportunity layouts, add it to the layout used for the demo.
8. Rerun preflight and confirm both `Quote` and `QuoteLineItem` can be described.

Use this CLI check after enablement:

```bash
sf sobject describe --sobject Quote --target-org <alias> --json
sf sobject describe --sobject QuoteLineItem --target-org <alias> --json
```

The setup guide must explain that feature enablement is an org-level administrative action and is separate from deploying the project metadata. Codex must not proceed with deployment of Quote-dependent metadata or Apex until the standard objects are available.

Perform the equivalent availability check for Order and OrderItem. If Orders are disabled, stop and provide the corresponding Salesforce **Order Settings** enablement step before deployment.

## 4. Business use case

### 4.1 Primary scenario

Given a Quote that:

- has Status equal to the configured accepted status;
- belongs to an Opportunity and Account;
- has not already been converted;
- contains at least one Quote Line Item;

when the Quote is converted, the system must:

1. Create one draft Order.
2. Copy the Account from the Quote/Opportunity context.
3. Set `EffectiveDate` using an injectable clock or date provider.
4. Copy the Quote Price Book to the Order.
5. Create one Order Item for each Quote Line Item.
6. Copy `PricebookEntryId`, `Quantity`, and `UnitPrice` to each Order Item.
7. Mark the Quote as converted only after the Order and all Order Items have been persisted successfully.
8. Return a result containing the created Order ID and the number of Order Items created.

### 4.2 Rejection scenarios

The service must reject conversion when:

- the Quote does not exist;
- Quotes outside the configured conversion status are ignored;
- the Quote was already converted;
- the Quote contains no lines;
- required Account or Price Book context is missing.

Use a small custom exception hierarchy or one clearly named domain exception. Messages must be stable enough for demonstration assertions without coupling tests to irrelevant punctuation.

### 4.3 Consistency scenario

If Order or Order Item persistence fails, the Quote must not be marked as converted.

The production repository should rely on normal Apex transaction rollback. The service must not catch and suppress persistence exceptions.

## 5. Required metadata

Create only the minimum custom metadata required for the demonstration.

The project does not define Quote, QuoteLineItem, Order, or OrderItem. These are standard Salesforce objects enabled through org settings. The project adds only the custom field and optional configuration described below.

### 5.1 Quote conversion marker

Create a custom lookup field on Quote:

- Label: `Converted Order`
- API name: `Converted_Order__c`
- Related object: Order
- Delete behavior: clear the lookup

The Quote is considered already converted when this field is populated.

### 5.2 Optional configuration

Preferred: create one Custom Metadata Type for demo configuration:

- Type: `Quote_Conversion_Policy__mdt`
- Record: `Default`
- Field: `Accepted_Quote_Status__c`, default value `Accepted`
- Field: `Use_Legacy_Implementation__c`, default value `false`; the trigger uses it to select the legacy or refactored `IQuoteToOrderService` implementation before constructing the trigger handler

If this adds too much ceremony for the live demo, use a clearly isolated constant in a policy class and document how to change it. Do not scatter the status literal across services and tests.

### 5.3 Permission set

Create a permission set named `Quote_Conversion` granting:

- Apex class access to demo entry points;
- read/write access to `Quote.Converted_Order__c`;
- the minimum object and field permissions needed to run the demonstration manually.

Do not grant Modify All Data.

## 6. Package structure

Use a standalone DX project structure similar to:

```text
force-app/main/default/
  classes/
  objects/Quote/fields/
  customMetadata/                    # if configuration metadata is used
  objects/Quote_Conversion_Policy__mdt/ # if configuration metadata is used
  permissionsets/
scripts/
  preflight.*
  deploy.*
  assign-permission-set.*
  run-demo-tests.*
  benchmark-tests.*
README.md
```

Provide scripts for Bash and PowerShell when practical. At minimum, all underlying `sf` commands must be documented so they can be run manually on Windows.

## 7. Naïve implementation

### 7.1 Class

Create:

```apex
LegacyQuoteToOrderService
```

Required public API:

```apex
public static Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds)
```

The class must intentionally demonstrate common coupling problems:

- static entry point;
- inline SOQL;
- direct construction of Order and Order Items;
- direct DML;
- direct use of `Date.today()`;
- direct Quote update;
- several responsibilities in one class.

The code must remain correct and readable. Do not introduce artificial inefficiency, unsafe bulk behavior, or deliberately bad security merely to strengthen the comparison.

### 7.2 Naïve tests

Create:

```apex
LegacyQuoteToOrderServiceTest
```

The primary happy-path test must construct a real Salesforce data graph containing at least:

- Account;
- Opportunity;
- Product2 records;
- Standard Pricebook PricebookEntry records;
- Quote;
- QuoteLineItem records.

It must execute the static service and then query:

- Order;
- OrderItem;
- Quote.

The assertions must verify the same business outcomes as the mock-based test.

Additional database-backed tests should cover only enough rejection behavior to illustrate duplication and setup cost. Avoid inflating test count solely to exaggerate timing differences.

Use `Test.getStandardPricebookId()` and do not depend on existing business data or `SeeAllData=true`.

## 8. Refactored design

### 8.1 Contracts

Create small Apex interfaces. Recommended contracts:

```apex
public interface IQuoteRepository {
    Quote findById(Id quoteId);
    void markConverted(Id quoteId, Id orderId);
}

public interface IQuoteLineRepository {
    List<QuoteLineItem> findByQuoteId(Id quoteId);
}

public interface IOrderRepository {
    Id save(Order orderRecord, List<OrderItem> orderItems);
}

public interface IDateProvider {
    Date today();
}
```

Exact naming may change if a clearer design emerges, but responsibilities must remain separated and mockable.

### 8.2 Production implementations

Create:

- `SalesforceQuoteRepository`
- `SalesforceQuoteLineRepository`
- `SalesforceOrderRepository`
- `SystemDateProvider`

Requirements:

- SOQL exists only in repository implementations.
- Order and Order Item DML exists only in `SalesforceOrderRepository`.
- Quote conversion-marker DML exists only in `SalesforceQuoteRepository`.
- The Order repository inserts the Order first, assigns its ID to Order Items, and inserts the items in the same transaction.
- Repository tests verify these Salesforce-specific behaviors.

### 8.3 Business service

Create:

```apex
QuoteToOrderService
```

Requirements:

- instance class, not a static utility;
- constructor injection of all required collaborators;
- no SOQL;
- no DML;
- no `Test.isRunningTest()`;
- no service-locator lookup from inside business methods;
- no use of `Date.today()` outside the injected date provider;
- business rules and mapping remain in the service;
- dependencies stored in private final fields where Apex permits;
- conversion method returns a small result object.

Recommended API:

```apex
public Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds)
```

### 8.4 Result type

Create:

```apex
QuoteToOrderResult
```

Minimum fields:

- `Id orderId`
- `Integer orderItemCount`

Prefer an immutable or effectively immutable value object.

### 8.5 Composition root

Use:

```apex
QuoteTriggerDependencies
```

Recommended API:

```apex
public static IQuoteToOrderService getNewService()
```

This method constructs the real DAO, date provider, and policy, then injects them into the service. The same class provides the narrow dependency overrides required to test trigger-level implementation selection.

The service must not call this factory internally.

## 9. Apex Mockery integration

Use the Salesforce Apex Mockery library built on the Apex Stub API.

The implementation must:

- document the chosen Apex Mockery release or source commit;
- pin that version for repeatable setup;
- avoid modifying library source unless required for an org namespace;
- document the cross-namespace Stub API limitation if relevant;
- keep third-party/library code separate from demo production code.

Tests should use the library’s actual API, including:

```apex
Mock.forType(...)
mock.stub
mock.spyOn(...)
spy.returns(...)
spy.whenCalledWith(...).thenReturn(...)
spy.throwsException(...)
spy.whenCalledWith(...).thenThrow(...)
Expect.that(spy).hasBeenCalledTimes(...)
Expect.that(spy).hasBeenCalledWith(...)
```

Use argument matchers only where they clarify intent. Avoid broad `Argument.any()` matchers when exact values are important to the business behavior.

## 10. Mock-based unit tests

Create:

```apex
QuoteToOrderServiceTest
```

These tests must:

- perform no SOQL;
- perform no DML;
- create no persisted Account, Opportunity, Quote, Product, PricebookEntry, Order, or line records;
- instantiate the real `QuoteToOrderService` with mocked dependencies;
- use in-memory SObjects as controlled inputs;
- assert business outcomes;
- verify only meaningful collaborator effects.

Required scenarios:

1. Accepted Quote with two lines creates the expected Order and two Order Items.
2. Quote is marked converted only after successful Order persistence.
3. Non-accepted Quote is rejected and no Order is saved.
4. Already converted Quote is rejected and no Order is saved.
5. Quote with no lines is rejected and no Order is saved.
6. Repository/persistence exception propagates and `markConverted` is not called.
7. Injected date provider controls `Order.EffectiveDate`.
8. Price, quantity, PricebookEntry, Account, and Price Book mappings are correct.

Interaction verification rules:

- verify one meaningful save call;
- verify conversion marking with the expected Quote and Order IDs;
- verify negative calls for rejection and failure scenarios;
- do not verify every repository read or exact internal call sequence unless it is itself a requirement.

## 11. Repository integration tests

Create focused tests for:

- `SalesforceQuoteRepository` query and conversion-marker update;
- `SalesforceQuoteLineRepository` query behavior;
- `SalesforceOrderRepository` insertion of one Order and its Order Items;
- one composition-root happy-path integration test using `QuoteTriggerDependencies.getNewService()`.

These tests may share a compact data factory. The factory must remain in test code and must not obscure which Salesforce records are required.

Do not duplicate every business-rule scenario at the integration level.

## 12. Benchmark design

Provide a repeatable benchmark script that compares:

- `LegacyQuoteToOrderServiceTest`
- `QuoteToOrderServiceTest`
- optionally the small repository/facade integration suite

Requirements:

1. Run each suite once as a warm-up.
2. Run each suite at least five measured times.
3. Execute suites sequentially to reduce org contention.
4. Use synchronous test execution where supported.
5. Save the raw Salesforce CLI JSON output for every run.
6. Report both Salesforce test execution duration and wall-clock duration when available.
7. Calculate median and range; do not rely on a single run.
8. Record org alias, date, API version, class count, method count, and whether parallel Apex testing was disabled.
9. Do not promise a predetermined speedup ratio.

Expected command family:

```bash
sf apex run test \
  --target-org <alias> \
  --tests LegacyQuoteToOrderServiceTest \
  --synchronous \
  --result-format json
```

The exact CLI options may be adjusted to the installed CLI version.

Generate:

```text
benchmark-results/
  raw/
  summary.csv
  summary.md
```

The summary must state that execution time varies by org load and automation.

## 13. Deployment workflow

Document and, where practical, script these steps:

1. Authenticate or confirm the target org alias.
2. Run preflight.
3. If Quote/QuoteLineItem or Order/OrderItem are unavailable, stop and enable the standard feature in Salesforce Setup.
4. Rerun preflight and require successful standard-object describes.
5. Install or deploy the pinned Apex Mockery dependency.
6. Deploy custom field/configuration metadata.
7. Deploy Apex classes and tests.
8. Assign `Quote_Conversion` permission set.
9. Run all demo tests.
10. Run benchmark suites.
11. Print commands for opening the org and locating the relevant records.

Use `sf project deploy start` and `sf apex run test` rather than deprecated `sfdx` commands.

No script may delete org data or metadata.

## 14. README requirements

The README must include:

- the teaching goal;
- architecture overview;
- class map;
- required org features;
- explicit steps for enabling standard Quotes and Orders when absent;
- Mockery installation/version information;
- deployment commands;
- permission-set assignment command;
- test commands;
- benchmark commands;
- expected live-demo sequence;
- known limitations;
- cleanup instructions limited to records created by the demo, if demo record creation is added.

Include a recommended live-demo flow:

1. Show naïve service.
2. Show naïve test setup.
3. Run and time naïve tests.
4. Show interfaces.
5. Show injected service constructor.
6. Show production factory.
7. Show mock-based happy-path test.
8. Show exception-path test.
9. Run and time mock-based tests.
10. Show retained repository/facade integration tests.

## 15. Code quality constraints

- Use an Apex API version supported by the target org and Apex Mockery release.
- Use `with sharing` or `inherited sharing` intentionally and document the choice.
- Avoid `SeeAllData=true`.
- Avoid hard-coded real record IDs.
- Avoid test-only branches in production code.
- Avoid global visibility unless required by packaging or Stub API behavior.
- Keep interfaces small.
- Keep the domain service free of persistence details.
- Use clear names suitable for presentation.
- Add comments only where they teach a non-obvious design decision.
- Do not add a large enterprise framework around the demo.

## 16. Acceptance criteria

The implementation is complete when:

1. A clean clone can be deployed using documented `sf` commands.
2. Preflight clearly reports missing org prerequisites, including a disabled Quotes or Orders feature.
3. The setup guide enables Salesforce standard Quote/QuoteLineItem rather than defining substitute custom objects.
4. All naïve, unit, repository, and composition tests pass in the target developer org.
5. Mock-based service tests execute without SOQL or DML.
6. The primary naïve test visibly creates the complete Salesforce data graph.
7. The refactored service contains no SOQL, DML, `Date.today()`, or `Test.isRunningTest()`.
8. Production assembly occurs outside the service.
9. The trigger handler demonstrates interface-based isolation from the conversion service.
10. At least one failure scenario is produced entirely through Mockery configuration.
11. Benchmark raw data and a median/range summary are generated.
12. No claimed timing result is hard-coded into code, documentation, or slides.
13. The README supports a presenter running the complete demonstration without inspecting implementation scripts first.

## 17. Implementation boundaries

Out of scope unless separately requested:

- CPQ or Revenue Cloud;
- Entitlement Management;
- Quote synchronization with Opportunity Products;
- UI development;
- Flow implementation;
- production-grade tax, discount, currency, shipping, or amendment logic;
- multi-currency support;
- managed packaging;
- replacing all legacy integration tests;
- performance claims derived from different orgs or different scenario counts.

## 18. Decisions Codex must confirm before deployment

Codex may generate the project before receiving these values, but must confirm them before writing to the org:

- target org alias;
- confirmation that standard Quotes and Orders have been enabled after any failed preflight check;
- accepted Quote status value if preflight does not find `Accepted`;
- whether Apex Mockery is already installed;
- whether the org has a namespace;
- whether configuration should use Custom Metadata or a policy constant;
- whether the user wants both Bash and PowerShell helper scripts.

All generated code should remain deployable before benchmark results are added.
