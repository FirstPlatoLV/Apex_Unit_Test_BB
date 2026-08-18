@IsTest
/**
 * One-time integration coverage for the generic Database wrapper.
 * These tests perform real DML for every supported operation and overload family;
 * their cost is infrastructure cost, not repeated service-unit-test cost.
 */
private class DMLExecutorTest {
  /** Verifies both insert overloads execute real Account DML successfully. */
  @IsTest
  static void insertRecordsTest() {

    DMLExecutor dml = new DMLExecutor();
    List<SObject> first = records(new Account(Name = 'one')),
      second = records(new Account(Name = 'two'));
    Assert.isTrue(dml.insertRecords(first, true)[0].isSuccess());
    Assert.isTrue(
      dml.insertRecords(second, true, System.AccessLevel.SYSTEM_MODE)[0]
        .isSuccess()
    );
  }

  /** Verifies both update overloads persist changes to existing records. */
  @IsTest
  static void updateRecordsTest() {

    Account first = new Account(Name = 'one'),
      second = new Account(Name = 'two');
    insert new List<Account>{ first, second };
    first.Name = 'updated one';
    second.Name = 'updated two';
    DMLExecutor dml = new DMLExecutor();
    Assert.isTrue(dml.updateRecords(records(first), true)[0].isSuccess());
    Assert.isTrue(
      dml.updateRecords(
          records(second),
          true,
          System.AccessLevel.SYSTEM_MODE
        )[0]
        .isSuccess()
    );
  }

  /** Verifies both external-ID upsert overloads complete successfully. */
  @IsTest
  static void upsertRecordsTest() {

    Account first = new Account(Name = 'one'),
      second = new Account(Name = 'two');
    insert new List<Account>{ first, second };
    DMLExecutor dml = new DMLExecutor();
    Assert.isTrue(
      dml.upsertRecords(records(first), Account.Id, true)[0].isSuccess()
    );
    Assert.isTrue(
      dml.upsertRecords(
          records(second),
          Account.Id,
          true,
          System.AccessLevel.SYSTEM_MODE
        )[0]
        .isSuccess()
    );
  }

  /** Verifies both delete overloads execute real soft-delete operations. */
  @IsTest
  static void deleteRecordsTest() {

    Account first = new Account(Name = 'one'),
      second = new Account(Name = 'two');
    insert new List<Account>{ first, second };
    DMLExecutor dml = new DMLExecutor();
    Assert.isTrue(dml.deleteRecords(records(first), true)[0].isSuccess());
    Assert.isTrue(
      dml.deleteRecords(
          records(second),
          true,
          System.AccessLevel.SYSTEM_MODE
        )[0]
        .isSuccess()
    );
  }

  /** Verifies both undelete overloads restore previously deleted records. */
  @IsTest
  static void undeleteRecordsTest() {

    Account first = new Account(Name = 'one'),
      second = new Account(Name = 'two');
    insert new List<Account>{ first, second };
    delete new List<Account>{ first, second };
    DMLExecutor dml = new DMLExecutor();
    Assert.isTrue(dml.undeleteRecords(records(first), true)[0].isSuccess());
    Assert.isTrue(
      dml.undeleteRecords(
          records(second),
          true,
          System.AccessLevel.SYSTEM_MODE
        )[0]
        .isSuccess()
    );
  }

  private static List<SObject> records(SObject record) {

    return new List<SObject>{ record };
  }
}
