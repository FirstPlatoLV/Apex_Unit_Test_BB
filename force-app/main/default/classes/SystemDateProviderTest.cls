@IsTest
private class SystemDateProviderTest {
  @IsTest
  static void todayTest() {
    Assert.areEqual(Date.today(), new SystemDateProvider().today());
  }
}
