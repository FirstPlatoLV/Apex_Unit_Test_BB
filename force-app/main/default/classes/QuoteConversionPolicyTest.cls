@IsTest
private class QuoteConversionPolicyTest {
  /** Verifies the injectable adapter delegates to the legacy policy source. */
  @IsTest
  static void getPolicyTest() {
    QuoteConversionPolicy policy = new QuoteConversionPolicy();

    Assert.areEqual(
      LegacyQuoteConversionPolicy.getPolicy(),
      policy.getPolicy()
    );
  }
}
