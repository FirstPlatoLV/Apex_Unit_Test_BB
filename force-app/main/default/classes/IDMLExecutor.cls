/**
 * Generic one-to-one abstraction over supported Database DML operations.
 *
 * It is intentionally object- and service-agnostic. Any DAO can inject this
 * contract to verify records, parameters, ordering, and failure handling without
 * executing DML in its own unit tests.
 */
public interface IDMLExecutor {
  Database.SaveResult[] insertRecords(List<SObject> records, Boolean allOrNone);
  Database.SaveResult[] insertRecords(
    List<SObject> records,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  );
  Database.UpsertResult[] upsertRecords(
    List<SObject> records,
    Schema.SObjectField externalIdField,
    Boolean allOrNone
  );
  Database.UpsertResult[] upsertRecords(
    List<SObject> records,
    Schema.SObjectField externalIdField,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  );
  Database.SaveResult[] updateRecords(List<SObject> records, Boolean allOrNone);
  Database.SaveResult[] updateRecords(
    List<SObject> records,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  );
  Database.DeleteResult[] deleteRecords(
    List<SObject> records,
    Boolean allOrNone
  );
  Database.DeleteResult[] deleteRecords(
    List<SObject> records,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  );
  Database.UndeleteResult[] undeleteRecords(
    List<SObject> records,
    Boolean allOrNone
  );
  Database.UndeleteResult[] undeleteRecords(
    List<SObject> records,
    Boolean allOrNone,
    System.AccessLevel accessLevel
  );
}
