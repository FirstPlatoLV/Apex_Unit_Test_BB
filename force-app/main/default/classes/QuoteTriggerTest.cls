@IsTest
private class QuoteTriggerTest {
  private static final Id QUOTE_ID = TestUtility.getFakeId(Quote.SObjectType);

  @IsTest
  static void legacyImplementationTest() {
    Mock policyMock = Mock.forType(IQuoteConversionPolicy.class),
      legacyServiceMock = Mock.forType(IQuoteToOrderService.class),
      newServiceMock = Mock.forType(IQuoteToOrderService.class);
    policyMock.spyOn('getPolicy')
      .returns(
        new Quote_Conversion_Policy__mdt(
          Accepted_Quote_Status__c = 'Accepted',
          Use_Legacy_Implementation__c = true
        )
      );
    MethodSpy legacyConvert = legacyServiceMock.spyOn('convertQuotes'),
      newConvert = newServiceMock.spyOn('convertQuotes');
    QuoteTriggerHandler handler = new QuoteTriggerHandler(
      (IQuoteConversionPolicy) policyMock.stub,
      (IQuoteToOrderService) legacyServiceMock.stub,
      (IQuoteToOrderService) newServiceMock.stub
    );

    handler.handle(
      System.TriggerOperation.AFTER_UPDATE,
      new List<Quote>{ new Quote(Id = QUOTE_ID, Status = 'Accepted') },
      new Map<Id, Quote>{
        QUOTE_ID => new Quote(Id = QUOTE_ID, Status = 'Draft')
      }
    );

    Expect.that(legacyConvert)
      .hasBeenCalledWith(Argument.jsonEquals(new Set<Id>{ QUOTE_ID }));
    Expect.that(newConvert).hasBeenCalledTimes(0);
  }

  @IsTest
  static void newImplementationTest() {
    Mock policyMock = Mock.forType(IQuoteConversionPolicy.class),
      legacyServiceMock = Mock.forType(IQuoteToOrderService.class),
      newServiceMock = Mock.forType(IQuoteToOrderService.class);
    policyMock.spyOn('getPolicy')
      .returns(
        new Quote_Conversion_Policy__mdt(
          Accepted_Quote_Status__c = 'Accepted',
          Use_Legacy_Implementation__c = false
        )
      );
    MethodSpy legacyConvert = legacyServiceMock.spyOn('convertQuotes'),
      newConvert = newServiceMock.spyOn('convertQuotes');
    QuoteTriggerHandler handler = new QuoteTriggerHandler(
      (IQuoteConversionPolicy) policyMock.stub,
      (IQuoteToOrderService) legacyServiceMock.stub,
      (IQuoteToOrderService) newServiceMock.stub
    );

    handler.handle(
      System.TriggerOperation.AFTER_UPDATE,
      new List<Quote>{ new Quote(Id = QUOTE_ID, Status = 'Accepted') },
      new Map<Id, Quote>{
        QUOTE_ID => new Quote(Id = QUOTE_ID, Status = 'Draft')
      }
    );

    Expect.that(newConvert)
      .hasBeenCalledWith(Argument.jsonEquals(new Set<Id>{ QUOTE_ID }));
    Expect.that(legacyConvert).hasBeenCalledTimes(0);
  }

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
