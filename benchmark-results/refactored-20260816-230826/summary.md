# Refactored implementation benchmark

- Org alias: unittestorg
- Date: 2026-08-16
- API version: 65.0
- Suite: QuoteToOrderServiceTest, QuoteToOrderDAOTest, SystemDateProviderTest, QuoteConversionPolicyTest
- One warm-up plus 5 measured runs, submitted and completed sequentially.
- Refactored: 4 classes, 16 methods; Salesforce median 213 ms (range 102-322); wall median 3481 ms (range 3466-10563).
