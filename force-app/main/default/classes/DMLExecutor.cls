public inherited sharing class DMLExecutor implements IDMLExecutor {
  public Database.SaveResult[] insertRecords(
    List<SObject> records,
    Boolean allOrNone
  ) {
    return Database.insert(records, allOrNone);
  }
  public Database.SaveResult[] insertRecords(
    List<SObject> records,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  ) {
    return Database.insert(records, allOrNone, accessLevel);
  }
  public Database.UpsertResult[] upsertRecords(
    List<SObject> records,
    Schema.SObjectField externalIdField,
    Boolean allOrNone
  ) {
    return Database.upsert(records, externalIdField, allOrNone);
  }
  public Database.UpsertResult[] upsertRecords(
    List<SObject> records,
    Schema.SObjectField externalIdField,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  ) {
    return Database.upsert(records, externalIdField, allOrNone, accessLevel);
  }
  public Database.SaveResult[] updateRecords(
    List<SObject> records,
    Boolean allOrNone
  ) {
    return Database.update(records, allOrNone);
  }
  public Database.SaveResult[] updateRecords(
    List<SObject> records,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  ) {
    return Database.update(records, allOrNone, accessLevel);
  }
  public Database.DeleteResult[] deleteRecords(
    List<SObject> records,
    Boolean allOrNone
  ) {
    return Database.delete(records, allOrNone);
  }
  public Database.DeleteResult[] deleteRecords(
    List<SObject> records,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  ) {
    return Database.delete(records, allOrNone, accessLevel);
  }
  public Database.UndeleteResult[] undeleteRecords(
    List<SObject> records,
    Boolean allOrNone
  ) {
    return Database.undelete(records, allOrNone);
  }
  public Database.UndeleteResult[] undeleteRecords(
    List<SObject> records,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  ) {
    return Database.undelete(records, allOrNone, accessLevel);
  }
}
