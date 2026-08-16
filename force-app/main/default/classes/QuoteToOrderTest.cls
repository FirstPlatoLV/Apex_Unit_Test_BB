@IsTest
private class QuoteToOrderTest {
  @IsTest
  static void convertTest() {
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      2
    );
    Map<Id, QuoteToOrderResult> results = QuoteToOrder.convert(
      new Set<Id>{ graph.quoteRecord.Id }
    );
    Id orderId = results.get(graph.quoteRecord.Id).orderId;
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
    Assert.isFalse(
      QuoteToOrder.convert(new Set<Id>{ skipped.quoteRecord.Id })
        .containsKey(skipped.quoteRecord.Id)
    );
  }
}
