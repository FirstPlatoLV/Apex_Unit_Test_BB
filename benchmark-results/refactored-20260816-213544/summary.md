# Refactored implementation benchmark

- Org alias: `<ORG_ALIAS>`
- Date: 2026-08-16
- API version: 65.0
- Suite: QuoteToOrderServiceTest, QuoteToOrderDAOTest, SystemDateProviderTest, QuoteConversionPolicyTest
- One warm-up plus 5 measured runs, submitted and completed sequentially.
- Refactored: 4 classes, 12 methods; Salesforce median 306 ms (range 102-492); wall median 5490 ms (range 3459-10506).
