@IsTest
private class QuoteConversionPolicyTest {
  @IsTest
  static void acceptedQuoteStatusTest() {
    QuoteConversionPolicy policy = new QuoteConversionPolicy();

    Assert.areEqual(
      LegacyQuoteConversionPolicy.acceptedQuoteStatus(),
      policy.acceptedQuoteStatus()
    );
  }
}
