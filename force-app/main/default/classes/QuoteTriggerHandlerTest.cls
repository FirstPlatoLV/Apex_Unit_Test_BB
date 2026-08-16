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

  @IsTest
  static void constructorTest() {
    Mock serviceMock = Mock.forType(IQuoteToOrderService.class);
    IQuoteToOrderService service = (IQuoteToOrderService) serviceMock.stub;

    Assert.isNotNull(new QuoteTriggerHandler(service));
  }

  @IsTest
  static void handleTest() {
    Mock serviceMock = Mock.forType(IQuoteToOrderService.class);
    IQuoteToOrderService service = (IQuoteToOrderService) serviceMock.stub;
    MethodSpy convert = serviceMock.spyOn('convert');

    new QuoteTriggerHandler(service)
      .handle(System.TriggerOperation.BEFORE_INSERT, null, null);

    Expect.that(convert).hasBeenCalledTimes(0);
  }

  @IsTest
  static void afterUpdateTest() {
    Mock serviceMock = Mock.forType(IQuoteToOrderService.class);
    IQuoteToOrderService service = (IQuoteToOrderService) serviceMock.stub;
    MethodSpy convert = serviceMock.spyOn('convert');
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
    QuoteTriggerHandler handler = new QuoteTriggerHandler(service);

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
