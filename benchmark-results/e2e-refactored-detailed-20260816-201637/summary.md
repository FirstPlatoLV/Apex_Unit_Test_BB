# Refactored E2E detailed benchmark

- Org alias: unittestorg
- Date: 2026-08-16
- Use_Legacy_Implementation__c: false (set manually in the org)
- QuoteTriggerTest uses actual Custom Metadata and production dependencies
- One warm-up plus five measured synchronous runs

## Per-run method timing

| Run | quoteTriggerTest | nonEligibleStatusTest | Suite Salesforce |    Wall |
| --: | ---------------: | --------------------: | ---------------: | ------: |
|   1 |          1380 ms |                693 ms |          2086 ms | 4475 ms |
|   2 |           572 ms |                424 ms |          1002 ms | 3474 ms |
|   3 |          1031 ms |                660 ms |          1706 ms | 4481 ms |
|   4 |           595 ms |                442 ms |          1047 ms | 3501 ms |
|   5 |          1183 ms |                702 ms |          1899 ms | 7507 ms |

## Summary

- quoteTriggerTest: median 1031 ms (range 572-1380 ms).
- nonEligibleStatusTest: median 660 ms (range 424-702 ms).
- Suite Salesforce median: 1706 ms (range 1002-2086 ms).
- Wall median: 4475 ms (range 3474-7507 ms).
