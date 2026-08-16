@IsTest
private class BrownbagDemoPolicyTest {
  @IsTest
  static void acceptedQuoteStatusTest() {
    Brownbag_Demo_Config__mdt config = Brownbag_Demo_Config__mdt.getInstance(
      'Default'
    );
    BrownbagDemoPolicy policy = new BrownbagDemoPolicy();
    Assert.areEqual(
      config?.Accepted_Quote_Status__c,
      policy.acceptedQuoteStatus()
    );
  }
}
