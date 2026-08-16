@IsTest
private class QuoteToOrderServiceFactoryTest {
  @IsTest
  static void createDefaultTest() {
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );

    QuoteToOrderResult result = QuoteToOrderServiceFactory.createDefault()
      .convert(graph.quoteRecord.Id);

    Assert.isNotNull(result.orderId);
    Assert.areEqual(1, result.orderItemCount);
    Assert.areEqual(
      result.orderId,
      [SELECT Converted_Order__c FROM Quote WHERE Id = :graph.quoteRecord.Id]
      .Converted_Order__c
    );
  }
}
