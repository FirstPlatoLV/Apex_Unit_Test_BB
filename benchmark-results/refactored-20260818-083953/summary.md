# Refactored implementation benchmark

- Org alias: unittestorg
- Date: 2026-08-18
- API version: 65.0
- Suite: QuoteToOrderServiceTest, QuoteToOrderDAOTest, SystemDateProviderTest, QuoteConversionPolicyTest
- One warm-up plus 5 measured runs, submitted and completed sequentially.
- Refactored: 4 classes, 15 methods; Salesforce median 280 ms (range 172-461); wall median 6494 ms (range 3450-9521).
