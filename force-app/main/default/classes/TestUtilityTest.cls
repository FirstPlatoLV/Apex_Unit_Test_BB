@IsTest
private class TestUtilityTest {

  /** Verifies fake IDs are valid, unique, 15-character, type-prefixed IDs. */
  @IsTest
  static void getFakeIdTest() {

    String firstAccountId = TestUtility.getFakeId(Account.SObjectType);
    String secondAccountId = TestUtility.getFakeId(Account.SObjectType);
    String quoteId = TestUtility.getFakeId(Quote.SObjectType);

    Assert.areEqual(
      Account.SObjectType.getDescribe().getKeyPrefix(),
      firstAccountId.left(3)
    );
    Assert.areEqual(
      Quote.SObjectType.getDescribe().getKeyPrefix(),
      quoteId.left(3)
    );
    Assert.areEqual(15, firstAccountId.length());
    Assert.areNotEqual(firstAccountId, secondAccountId);
    Assert.areEqual(
      firstAccountId,
      String.valueOf(Id.valueOf(firstAccountId)).left(15)
    );
  }
}
