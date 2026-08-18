@IsTest
private class LegacyQuoteConversionPolicyTest {
  /** Verifies the static legacy accessor returns the org's Default policy. */
  @IsTest
  static void getPolicyTest() {

    Quote_Conversion_Policy__mdt config = Quote_Conversion_Policy__mdt.getInstance(
      'Default'
    );

    Assert.areEqual(config, LegacyQuoteConversionPolicy.getPolicy());
  }
}
