@IsTest
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
      dateMock = Mock.forType(IDateProvider.class);
    IQuoteToOrderDAO dao = (IQuoteToOrderDAO) daoMock.stub;
    IDateProvider dates = (IDateProvider) dateMock.stub;
    QuoteToOrderService service() {
      return new QuoteToOrderService(dao, dates, 'Accepted');
    }
  }

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
    QuoteToOrderResult result = f.service().convert(QUOTE_ID);
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
      failed.service().convert(QUOTE_ID);
      Assert.fail('Expected DAO failure');
    } catch (DAOFailureException e) {
      Assert.areEqual('Order persistence failed', e.getMessage());
    }
    Expect.that(failedSave).hasBeenCalledTimes(1);
    Expect.that(failedMark).hasBeenCalledTimes(0);
  }
  @IsTest
  static void validateTest() {
    assertRejected(
      configured(
        quoteWith('Draft', null, ACCOUNT_ID, PRICEBOOK_ID),
        twoLines()
      ),
      'Quote status is not accepted'
    );
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
      f.service().convert(QUOTE_ID);
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
