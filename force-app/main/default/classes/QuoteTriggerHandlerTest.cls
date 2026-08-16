@IsTest
/**
 * Isolates trigger-context filtering from conversion behavior.
 * A mocked service proves which Quote IDs would be delegated without invoking
 * either implementation or performing DML.
 */
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

  private class ConversionFailureException extends Exception {
  }

  private class Fixture {
    Mock serviceMock = Mock.forType(IQuoteToOrderService.class);
    IQuoteToOrderService service = (IQuoteToOrderService) serviceMock.stub;

    QuoteTriggerHandler handler() {
      return new QuoteTriggerHandler(service);
    }
  }

  /** Verifies the handler accepts an IQuoteToOrderService dependency. */
  @IsTest
  static void constructorTest() {
    Fixture f = new Fixture();

    Assert.isNotNull(new QuoteTriggerHandler(f.service));
  }

  /** Verifies trigger operations other than after update do not invoke conversion. */
  @IsTest
  static void handleTest() {
    Fixture f = new Fixture();
    MethodSpy convert = f.serviceMock.spyOn('convertQuotes');

    f.handler().handle(System.TriggerOperation.BEFORE_INSERT, null, null);

    Expect.that(convert).hasBeenCalledTimes(0);
  }

  /**
   * Verifies after update delegates only status-changed, unconverted Quote IDs,
   * and makes no service call when every record is ineligible.
   */
  @IsTest
  static void afterUpdateTest() {
    Fixture f = new Fixture();
    MethodSpy convert = f.serviceMock.spyOn('convertQuotes');
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

    // Scenario: a mocked service exception becomes a record-level error only
    // on the Quote included in the failed conversion attempt.
    Fixture failed = new Fixture();
    MethodSpy failedConvert = failed.serviceMock.spyOn('convertQuotes');
    failedConvert.throwsException(
      new ConversionFailureException('DAO unavailable')
    );
    Quote changedQuote = new Quote(Id = CHANGED_QUOTE_ID, Status = 'Accepted');
    Quote unchangedQuote = new Quote(Id = UNCHANGED_QUOTE_ID, Status = 'Draft');
    List<Quote> failedNewQuotes = new List<Quote>{
      changedQuote,
      unchangedQuote
    };
    Map<Id, Quote> failedOldQuotesById = new Map<Id, Quote>{
      CHANGED_QUOTE_ID => new Quote(Id = CHANGED_QUOTE_ID, Status = 'Draft'),
      UNCHANGED_QUOTE_ID => new Quote(Id = UNCHANGED_QUOTE_ID, Status = 'Draft')
    };

    failed.handler()
      .handle(
        System.TriggerOperation.AFTER_UPDATE,
        failedNewQuotes,
        failedOldQuotesById
      );

    Expect.that(failedConvert)
      .hasBeenCalledWith(Argument.jsonEquals(new Set<Id>{ CHANGED_QUOTE_ID }));
    Expect.that(failedConvert).hasBeenCalledTimes(1);
    Assert.isTrue(changedQuote.hasErrors());
    Assert.areEqual(1, changedQuote.getErrors().size());
    Assert.areEqual(
      'Quote conversion failed: DAO unavailable',
      changedQuote.getErrors()[0].getMessage()
    );
    Assert.isFalse(unchangedQuote.hasErrors());
  }
}
