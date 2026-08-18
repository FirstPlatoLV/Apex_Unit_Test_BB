# Refactored implementation benchmark

- Org alias: unittestorg
- Date: 2026-08-18
- API version: 65.0
- Suite: QuoteToOrderServiceTest, QuoteToOrderDAOTest, SystemDateProviderTest, QuoteConversionPolicyTest
- One warm-up plus 5 measured runs, submitted and completed sequentially.
- Refactored: 4 classes, 15 methods; Salesforce median 334 ms (range 172-530); wall median 4460 ms (range 3446-8531).
