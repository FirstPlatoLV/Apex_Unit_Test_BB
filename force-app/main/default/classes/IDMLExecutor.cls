public interface IDMLExecutor {
    Database.SaveResult[] insertRecords(List<SObject> records, Boolean allOrNone);
    Database.SaveResult[] insertRecords(List<SObject> records, Boolean allOrNone, System.AccessLevel accessLevel);
    Database.UpsertResult[] upsertRecords(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone);
    Database.UpsertResult[] upsertRecords(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone, System.AccessLevel accessLevel);
    Database.SaveResult[] updateRecords(List<SObject> records, Boolean allOrNone);
    Database.SaveResult[] updateRecords(List<SObject> records, Boolean allOrNone, System.AccessLevel accessLevel);
    Database.DeleteResult[] deleteRecords(List<SObject> records, Boolean allOrNone);
    Database.DeleteResult[] deleteRecords(List<SObject> records, Boolean allOrNone, System.AccessLevel accessLevel);
    Database.UndeleteResult[] undeleteRecords(List<SObject> records, Boolean allOrNone);
    Database.UndeleteResult[] undeleteRecords(List<SObject> records, Boolean allOrNone, System.AccessLevel accessLevel);
}
