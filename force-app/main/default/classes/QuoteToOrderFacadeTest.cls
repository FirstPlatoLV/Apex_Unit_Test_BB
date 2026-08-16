@IsTest
private class QuoteToOrderFacadeTest {
  @IsTest
  static void convertTest() {
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      2
    );
    Id orderId = QuoteToOrder.convert(graph.quoteRecord.Id);
    Order saved = [
      SELECT AccountId, Pricebook2Id, Status
      FROM Order
      WHERE Id = :orderId
    ];
    Assert.areEqual(graph.account.Id, saved.AccountId);
    Assert.areEqual(Test.getStandardPricebookId(), saved.Pricebook2Id);
    Assert.areEqual('Draft', saved.Status);
    Assert.areEqual(
      2,
      [SELECT COUNT() FROM OrderItem WHERE OrderId = :orderId]
    );
    Assert.areEqual(
      orderId,
      [SELECT Converted_Order__c FROM Quote WHERE Id = :graph.quoteRecord.Id]
      .Converted_Order__c
    );
    Assert.areEqual(0, QuoteToOrder.convert(new Set<Id>()).size());

    QuoteToOrderTestDataFactory.Graph skipped = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );
    skipped.quoteRecord.Status = 'Draft';
    update skipped.quoteRecord;
    Assert.isNull(QuoteToOrder.convert(skipped.quoteRecord.Id));
  }
}
