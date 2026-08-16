@IsTest
private class QuoteTriggerTest {
  @IsTest
  static void quoteTriggerTest() {
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      2
    );
    graph.quoteRecord.Status = 'Draft';
    update graph.quoteRecord;

    Test.startTest();
    graph.quoteRecord.Status = LegacyQuoteConversionPolicy.getPolicy()
      .Accepted_Quote_Status__c;
    update graph.quoteRecord;
    Test.stopTest();

    Quote convertedQuote = [
      SELECT Converted_Order__c
      FROM Quote
      WHERE Id = :graph.quoteRecord.Id
    ];
    Assert.isNotNull(convertedQuote.Converted_Order__c);
    Assert.areEqual(
      2,
      [
        SELECT COUNT()
        FROM OrderItem
        WHERE OrderId = :convertedQuote.Converted_Order__c
      ]
    );
  }

  @IsTest
  static void nonEligibleStatusTest() {
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );

    Test.startTest();
    graph.quoteRecord.Status = 'Draft';
    update graph.quoteRecord;
    Test.stopTest();

    Quote unchangedQuote = [
      SELECT Converted_Order__c
      FROM Quote
      WHERE Id = :graph.quoteRecord.Id
    ];
    Assert.isNull(unchangedQuote.Converted_Order__c);
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Order WHERE AccountId = :graph.account.Id]
    );
  }
}
