@IsTest
private class QuoteTriggerDependenciesTest {
  @IsTest
  static void getPolicyTest() {
    Quote_Conversion_Policy__mdt actualPolicy = QuoteTriggerDependencies.getPolicy();

    Assert.areEqual(LegacyQuoteConversionPolicy.getPolicy(), actualPolicy);
  }

  @IsTest
  static void getLegacyServiceTest() {
    IQuoteToOrderService actualService = QuoteTriggerDependencies.getLegacyService();

    Assert.isTrue(actualService instanceof LegacyQuoteToOrderService);
  }

  @IsTest
  static void getNewServiceTest() {
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );

    QuoteToOrderResult result = QuoteTriggerDependencies.getNewService()
      .convertQuotes(new Set<Id>{ graph.quoteRecord.Id })
      .get(graph.quoteRecord.Id);

    Assert.isNotNull(result.orderId);
    Assert.areEqual(1, result.orderItemCount);
    Assert.areEqual(
      result.orderId,
      [SELECT Converted_Order__c FROM Quote WHERE Id = :graph.quoteRecord.Id]
      .Converted_Order__c
    );
  }
}
