# Legacy implementation benchmark

- Org alias: unittestorg
- Date: 2026-08-16
- API version: 65.0
- Suite: LegacyQuoteToOrderServiceTest, LegacyQuoteConversionPolicyTest
- One warm-up plus 5 measured runs, submitted and completed sequentially.
- Legacy: 2 classes, 12 test methods plus one @TestSetup method; Salesforce median 2261 ms (range 1444-2774); wall median 8535 ms (range 6490-17579).
