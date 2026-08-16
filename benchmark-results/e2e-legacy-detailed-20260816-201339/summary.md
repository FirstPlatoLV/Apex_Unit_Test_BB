# Legacy E2E detailed benchmark

- Org alias: unittestorg
- Date: 2026-08-16
- Use_Legacy_Implementation__c: true (set manually in the org)
- QuoteTriggerTest uses actual Custom Metadata and production dependencies
- One warm-up plus five measured synchronous runs

## Per-run method timing

| Run | quoteTriggerTest | nonEligibleStatusTest | Suite Salesforce |    Wall |
| --: | ---------------: | --------------------: | ---------------: | ------: |
|   1 |          1092 ms |                570 ms |          1676 ms | 4463 ms |
|   2 |          1288 ms |                730 ms |          2043 ms | 4500 ms |
|   3 |           584 ms |                458 ms |          1051 ms | 3486 ms |
|   4 |           617 ms |                460 ms |          1085 ms | 3450 ms |
|   5 |           585 ms |                355 ms |           951 ms | 3464 ms |

## Summary

- quoteTriggerTest: median 617 ms (range 584-1288 ms).
- nonEligibleStatusTest: median 460 ms (range 355-730 ms).
- Suite Salesforce median: 1085 ms (range 951-2043 ms).
- Wall median: 3486 ms (range 3450-4500 ms).
