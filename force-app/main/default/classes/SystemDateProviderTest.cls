@IsTest
private class SystemDateProviderTest {
  /** Verifies the production date provider returns the current system date. */
  @IsTest
  static void todayTest() {
    Assert.areEqual(Date.today(), new SystemDateProvider().today());
  }
}
