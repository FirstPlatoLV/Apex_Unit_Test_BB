@IsTest
private class QuoteConversionPolicyTest {
  @IsTest
  static void getPolicyTest() {
    QuoteConversionPolicy policy = new QuoteConversionPolicy();

    Assert.areEqual(
      LegacyQuoteConversionPolicy.getPolicy(),
      policy.getPolicy()
    );
  }
}
