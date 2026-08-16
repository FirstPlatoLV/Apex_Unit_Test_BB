# Brown-bag demonstration runbook

1. Run `scripts/preflight.ps1 unittestorg`; point out standard objects, `Accepted`, and Apex Mockery 2.3.0.1.
2. Show `LegacyQuoteToOrderService.convert(Set<Id>)` and `LegacyQuoteToOrderDAO`: the code is responsibly bulkified and layered, but concrete static calls and the system clock remain non-substitutable.
3. Show the complete data graph in `LegacyQuoteToOrderServiceTest.cls`, then run it.
4. Show the four interfaces, injected `QuoteToOrderService`, production factory, and static façade.
5. Show the mock happy path: controlled in-memory records, exact mappings, result and interaction assertions.
6. Show the persistence-failure test and zero-call conversion-marker verification.
7. Run the mock suite and compare `benchmark-results/summary.md`.
8. Show generic `IDMLExecutor`: DAO mapping and call orchestration are tested with mocks, while the reusable default executor mirrors bulk insert, upsert, update, delete, and undelete database operations.
9. Close with DAO and façade integration tests: platform behavior stays integrated; rule permutations do not need the database.
