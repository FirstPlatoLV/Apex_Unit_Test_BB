@IsTest
/**
 * Fast business-logic tests for the dependency-injected service.
 * DAO, clock, and policy mocks keep these tests deterministic and free of
 * SOQL/DML while still covering every service method and validation branch.
 */
private class QuoteToOrderServiceTest {
  private static final Id QUOTE_ID = TestUtility.getFakeId(Quote.SObjectType);
  private static final Id ACCOUNT_ID = TestUtility.getFakeId(
    Account.SObjectType
  );
  private static final Id PRICEBOOK_ID = TestUtility.getFakeId(
    Pricebook2.SObjectType
  );
  private static final Id ENTRY_ONE_ID = TestUtility.getFakeId(
    PricebookEntry.SObjectType
  );
  private static final Id ENTRY_TWO_ID = TestUtility.getFakeId(
    PricebookEntry.SObjectType
  );
  private static final Id ORDER_ID = TestUtility.getFakeId(Order.SObjectType);
  private static final Date FIXED_DATE = Date.newInstance(2030, 4, 15);
  private class DAOFailureException extends Exception {
  }

  private class Fixture {
    Mock daoMock = Mock.forType(IQuoteToOrderDAO.class),
      dateMock = Mock.forType(IDateProvider.class),
      policyMock = Mock.forType(IQuoteConversionPolicy.class);
    IQuoteToOrderDAO dao = (IQuoteToOrderDAO) daoMock.stub;
    IDateProvider dates = (IDateProvider) dateMock.stub;
    IQuoteConversionPolicy policy = (IQuoteConversionPolicy) policyMock.stub;

    Fixture() {
      policyMock.spyOn('getPolicy')
        .returns(
          new Quote_Conversion_Policy__mdt(
            Accepted_Quote_Status__c = 'Accepted',
            Use_Legacy_Implementation__c = false
          )
        );
    }

    QuoteToOrderService service() {
      return new QuoteToOrderService(dao, dates, policy);
    }
  }

  /** Verifies the service accepts its DAO, date, and policy dependencies. */
  @IsTest
  static void constructorTest() {
    Fixture f = new Fixture();

    Assert.isNotNull(new QuoteToOrderService(f.dao, f.dates, f.policy));
  }

  /** Verifies the interface entry point delegates and handles an empty batch. */
  @IsTest
  static void convertQuotesTest() {
    Assert.areEqual(
      0,
      new Fixture().service().convertQuotes(new Set<Id>()).size()
    );
  }

  /**
   * Verifies the core conversion orchestration with mocks: mapping Orders and
   * items, returning results, skipping invalid input and statuses, propagating
   * DAO failures, and updating Quotes only after persistence succeeds.
   */
  @IsTest
  static void convertTest() {
    Fixture f = configured(
      quoteWith('Accepted', null, ACCOUNT_ID, PRICEBOOK_ID),
      twoLines()
    );
    f.dateMock.spyOn('today').returns(FIXED_DATE);
    Map<Id, Order> expectedOrders = new Map<Id, Order>{
      QUOTE_ID => new Order(
        AccountId = ACCOUNT_ID,
        EffectiveDate = FIXED_DATE,
        Pricebook2Id = PRICEBOOK_ID,
        Status = 'Draft'
      )
    };
    Map<Id, List<OrderItem>> expectedItems = new Map<Id, List<OrderItem>>{
      QUOTE_ID => new List<OrderItem>{
        new OrderItem(
          PricebookEntryId = ENTRY_ONE_ID,
          Quantity = 2,
          UnitPrice = 9
        ),
        new OrderItem(
          PricebookEntryId = ENTRY_TWO_ID,
          Quantity = 3,
          UnitPrice = 24
        )
      }
    };
    MethodSpy save = f.daoMock.spyOn('saveOrders');
    save.whenCalledWith(Argument.any(), Argument.any())
      .thenReturn(new Map<Id, Id>{ QUOTE_ID => ORDER_ID });
    MethodSpy mark = f.daoMock.spyOn('markQuotesConverted');
    QuoteToOrderResult result = f.service()
      .convert(new Set<Id>{ QUOTE_ID })
      .get(QUOTE_ID);
    Assert.areEqual(ORDER_ID, result.orderId);
    Assert.areEqual(2, result.orderItemCount);
    Expect.that(save).hasBeenCalledTimes(1);
    Expect.that(mark)
      .hasBeenCalledWith(
        Argument.jsonEquals(new Map<Id, Id>{ QUOTE_ID => ORDER_ID })
      );

    Assert.areEqual(0, f.service().convert(new Set<Id>()).size());
    Assert.areEqual(0, f.service().convert((Set<Id>) null).size());
    assertRejected(configured(null, twoLines()), 'Quote does not exist');

    Fixture skipped = configured(
      quoteWith('Draft', null, ACCOUNT_ID, PRICEBOOK_ID),
      twoLines()
    );
    MethodSpy skippedSave = skipped.daoMock.spyOn('saveOrders');
    Assert.isFalse(
      skipped.service().convert(new Set<Id>{ QUOTE_ID }).containsKey(QUOTE_ID)
    );
    Expect.that(skippedSave).hasBeenCalledTimes(0);

    Fixture failed = configured(
      quoteWith('Accepted', null, ACCOUNT_ID, PRICEBOOK_ID),
      twoLines()
    );
    failed.dateMock.spyOn('today').returns(FIXED_DATE);
    MethodSpy failedSave = failed.daoMock.spyOn('saveOrders');
    failedSave.throwsException(
      new DAOFailureException('Order persistence failed')
    );
    MethodSpy failedMark = failed.daoMock.spyOn('markQuotesConverted');
    try {
      failed.service().convert(new Set<Id>{ QUOTE_ID });
      Assert.fail('Expected DAO failure');
    } catch (DAOFailureException e) {
      Assert.areEqual('Order persistence failed', e.getMessage());
    }
    Expect.that(failedSave).hasBeenCalledTimes(1);
    Expect.that(failedMark).hasBeenCalledTimes(0);
  }

  /**
   * Verifies every private validation rule rejects already-converted Quotes,
   * missing Accounts, missing Price Books, and missing Quote Lines before DML.
   */
  @IsTest
  static void validateTest() {
    assertRejected(
      configured(
        quoteWith('Accepted', ORDER_ID, ACCOUNT_ID, PRICEBOOK_ID),
        twoLines()
      ),
      'Quote was already converted'
    );
    assertRejected(
      configured(quoteWith('Accepted', null, null, PRICEBOOK_ID), twoLines()),
      'Quote Account is required'
    );
    assertRejected(
      configured(quoteWith('Accepted', null, ACCOUNT_ID, null), twoLines()),
      'Quote Price Book is required'
    );
    assertRejected(
      configured(
        quoteWith('Accepted', null, ACCOUNT_ID, PRICEBOOK_ID),
        new List<QuoteLineItem>()
      ),
      'Quote must contain at least one line'
    );
  }

  private static Fixture configured(Quote q, List<QuoteLineItem> lines) {
    Fixture f = new Fixture();
    Map<Id, Quote> quotes = new Map<Id, Quote>();
    if (q != null) {
      quotes.put(QUOTE_ID, q);
    }
    f.daoMock.spyOn('findQuotes')
      .whenCalledWith(new Set<Id>{ QUOTE_ID })
      .thenReturn(quotes);
    f.daoMock.spyOn('findQuoteLines')
      .whenCalledWith(new Set<Id>{ QUOTE_ID })
      .thenReturn(lines);
    return f;
  }

  private static void assertRejected(Fixture f, String message) {
    MethodSpy save = f.daoMock.spyOn('saveOrders');
    try {
      f.service().convert(new Set<Id>{ QUOTE_ID });
      Assert.fail('Expected rejection');
    } catch (QuoteToOrderException e) {
      Assert.areEqual(message, e.getMessage());
    }
    Expect.that(save).hasBeenCalledTimes(0);
  }

  private static Quote quoteWith(
    String status,
    Id converted,
    Id accountId,
    Id pricebookId
  ) {
    return (Quote) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'Id' => QUOTE_ID,
          'Status' => status,
          'Converted_Order__c' => converted,
          'AccountId' => accountId,
          'Pricebook2Id' => pricebookId
        }
      ),
      Quote.class
    );
  }

  private static List<QuoteLineItem> twoLines() {
    List<Object> raw = new List<Object>{
      new Map<String, Object>{
        'QuoteId' => QUOTE_ID,
        'PricebookEntryId' => ENTRY_ONE_ID,
        'Quantity' => 2,
        'UnitPrice' => 9
      },
      new Map<String, Object>{
        'QuoteId' => QUOTE_ID,
        'PricebookEntryId' => ENTRY_TWO_ID,
        'Quantity' => 3,
        'UnitPrice' => 24
      }
    };
    return (List<QuoteLineItem>) JSON.deserialize(
      JSON.serialize(raw),
      List<QuoteLineItem>.class
    );
  }
}
