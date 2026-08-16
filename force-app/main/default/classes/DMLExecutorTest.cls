@IsTest
private class DMLExecutorTest {
    @IsTest static void wrapsGenericBulkDatabaseOperations() {
        DMLExecutor dml = new DMLExecutor();
        List<SObject> first = records(new Account(Name='DML executor one'));
        List<SObject> second = records(new Account(Name='DML executor two'));
        assertSucceeded(dml.insertRecords(first,true));
        assertSucceeded(dml.insertRecords(second,true,System.AccessLevel.SYSTEM_MODE));
        ((Account)first[0]).Name='DML executor one updated'; ((Account)second[0]).Name='DML executor two updated';
        assertSucceeded(dml.updateRecords(first,true));
        assertSucceeded(dml.updateRecords(second,true,System.AccessLevel.SYSTEM_MODE));
        assertUpserted(dml.upsertRecords(first,Account.Id,true));
        assertUpserted(dml.upsertRecords(second,Account.Id,true,System.AccessLevel.SYSTEM_MODE));
        assertDeleted(dml.deleteRecords(first,true));
        assertDeleted(dml.deleteRecords(second,true,System.AccessLevel.SYSTEM_MODE));
        assertUndeleted(dml.undeleteRecords(first,true));
        assertUndeleted(dml.undeleteRecords(second,true,System.AccessLevel.SYSTEM_MODE));
    }
    private static List<SObject> records(SObject record){ return new List<SObject>{record}; }
    private static void assertSucceeded(Database.SaveResult[] r){ System.assertEquals(1,r.size()); System.assert(r[0].isSuccess()); }
    private static void assertUpserted(Database.UpsertResult[] r){ System.assertEquals(1,r.size()); System.assert(r[0].isSuccess()); }
    private static void assertDeleted(Database.DeleteResult[] r){ System.assertEquals(1,r.size()); System.assert(r[0].isSuccess()); }
    private static void assertUndeleted(Database.UndeleteResult[] r){ System.assertEquals(1,r.size()); System.assert(r[0].isSuccess()); }
}
