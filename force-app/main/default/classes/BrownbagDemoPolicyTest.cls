@IsTest
private class BrownbagDemoPolicyTest {
  @IsTest
  static void acceptedQuoteStatusTest() {
    Assert.areEqual('Accepted', BrownbagDemoPolicy.acceptedQuoteStatus());

    assertMissingConfiguration(null);
    assertMissingConfiguration(new Brownbag_Demo_Config__mdt());
  }

  private static void assertMissingConfiguration(
    Brownbag_Demo_Config__mdt config
  ) {
    try {
      BrownbagDemoPolicy.acceptedQuoteStatus(config);
      Assert.fail('Expected missing configuration failure');
    } catch (QuoteToOrderException error) {
      Assert.areEqual(
        'Accepted Quote status is not configured',
        error.getMessage()
      );
    }
  }
}
