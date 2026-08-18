# Refactored implementation benchmark

- Org alias: unittestorg
- Date: 2026-08-18
- API version: 65.0
- Suite: QuoteToOrderServiceTest, QuoteToOrderDAOTest, SystemDateProviderTest, QuoteConversionPolicyTest
- One warm-up plus 5 measured runs, submitted and completed sequentially.
- Refactored: 4 classes, 15 methods; Salesforce median 350 ms (range 246-518); wall median 3446 ms (range 3433-3462).
