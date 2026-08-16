# Implementation benchmark

- Org alias: unittestorg
- Date: 2026-08-16
- One warm-up plus five measured runs per suite
- Suites alternated sequentially; no parallel execution
- Excluded: QuoteTriggerTest, DMLExecutorTest, and shared infrastructure tests

- legacy: 2 classes, 12 methods; Salesforce median 7646 ms (range 5006-9294); wall median 12553 ms (range 8523-16572).
- refactored: 4 classes, 11 methods; Salesforce median 291 ms (range 260-484); wall median 4477 ms (range 3472-8530).
