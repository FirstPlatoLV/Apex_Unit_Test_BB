@IsTest
private class LegacyQuoteConversionPolicyTest {
  @IsTest
  static void acceptedQuoteStatusTest() {
    Quote_Conversion_Policy__mdt config = Quote_Conversion_Policy__mdt.getInstance(
      'Default'
    );

    Assert.areEqual(
      config?.Accepted_Quote_Status__c,
      LegacyQuoteConversionPolicy.acceptedQuoteStatus()
    );
  }
}
