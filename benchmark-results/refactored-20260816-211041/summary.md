# Refactored implementation benchmark

- Org alias: unittestorg
- Date: 2026-08-16
- API version: 65.0
- Suite: QuoteToOrderServiceTest, QuoteToOrderDAOTest, SystemDateProviderTest, QuoteConversionPolicyTest
- One warm-up plus 5 measured runs, submitted and completed sequentially.
- Refactored: 4 classes, 12 methods; Salesforce median 308 ms (range 191-463); wall median 3456 ms (range 3440-5476).
