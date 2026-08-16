@IsTest
private class QuoteTriggerHandlerTest {
  private static final Id CHANGED_QUOTE_ID = TestUtility.getFakeId(
    Quote.SObjectType
  );
  private static final Id UNCHANGED_QUOTE_ID = TestUtility.getFakeId(
    Quote.SObjectType
  );
  private static final Id CONVERTED_QUOTE_ID = TestUtility.getFakeId(
    Quote.SObjectType
  );
  private static final Id ORDER_ID = TestUtility.getFakeId(Order.SObjectType);

  private class Fixture {
    Mock policyMock = Mock.forType(IQuoteConversionPolicy.class),
      legacyServiceMock = Mock.forType(IQuoteToOrderService.class),
      newServiceMock = Mock.forType(IQuoteToOrderService.class);
    IQuoteConversionPolicy policy = (IQuoteConversionPolicy) policyMock.stub;
    IQuoteToOrderService legacyService = (IQuoteToOrderService) legacyServiceMock.stub;
    IQuoteToOrderService newService = (IQuoteToOrderService) newServiceMock.stub;

    Fixture() {
      policyMock.spyOn('getPolicy')
        .returns(
          new Quote_Conversion_Policy__mdt(
            Accepted_Quote_Status__c = 'Accepted',
            Use_Legacy_Implementation__c = false
          )
        );
    }

    QuoteTriggerHandler handler() {
      return new QuoteTriggerHandler(policy, legacyService, newService);
    }
  }

  @IsTest
  static void constructorTest() {
    Fixture f = new Fixture();

    Assert.isNotNull(
      new QuoteTriggerHandler(f.policy, f.legacyService, f.newService)
    );
  }

  @IsTest
  static void handleTest() {
    Fixture f = new Fixture();
    MethodSpy convert = f.newServiceMock.spyOn('convertQuotes');

    f.handler().handle(System.TriggerOperation.BEFORE_INSERT, null, null);

    Expect.that(convert).hasBeenCalledTimes(0);
  }

  @IsTest
  static void afterUpdateTest() {
    Fixture f = new Fixture();
    MethodSpy convert = f.newServiceMock.spyOn('convertQuotes');
    List<Quote> newQuotes = new List<Quote>{
      new Quote(Id = CHANGED_QUOTE_ID, Status = 'Accepted'),
      new Quote(Id = UNCHANGED_QUOTE_ID, Status = 'Draft'),
      new Quote(
        Id = CONVERTED_QUOTE_ID,
        Status = 'Accepted',
        Converted_Order__c = ORDER_ID
      )
    };
    Map<Id, Quote> oldQuotesById = new Map<Id, Quote>{
      CHANGED_QUOTE_ID => new Quote(Id = CHANGED_QUOTE_ID, Status = 'Draft'),
      UNCHANGED_QUOTE_ID => new Quote(
        Id = UNCHANGED_QUOTE_ID,
        Status = 'Draft'
      ),
      CONVERTED_QUOTE_ID => new Quote(Id = CONVERTED_QUOTE_ID, Status = 'Draft')
    };
    QuoteTriggerHandler handler = f.handler();

    handler.handle(
      System.TriggerOperation.AFTER_UPDATE,
      new List<Quote>{ newQuotes[1], newQuotes[2] },
      oldQuotesById
    );

    Expect.that(convert).hasBeenCalledTimes(0);

    handler.handle(
      System.TriggerOperation.AFTER_UPDATE,
      newQuotes,
      oldQuotesById
    );

    Expect.that(convert)
      .hasBeenCalledWith(Argument.jsonEquals(new Set<Id>{ CHANGED_QUOTE_ID }));
    Expect.that(convert).hasBeenCalledTimes(1);
  }
}
