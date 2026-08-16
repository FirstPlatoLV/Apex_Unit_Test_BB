@IsTest
/**
 * Focused tests for data-access behavior.
 * Query tests only verify that the expected SOQL boundary is crossed; E2E tests
 * prove the queries return the fields needed for conversion. Write tests mock
 * IDMLExecutor to inspect mapping and call parameters without database writes.
 */
private class QuoteToOrderDAOTest {
  private static final Id QUOTE_ONE_ID = TestUtility.getFakeId(
    Quote.SObjectType
  );
  private static final Id QUOTE_TWO_ID = TestUtility.getFakeId(
    Quote.SObjectType
  );
  private static final Id ORDER_ONE_ID = TestUtility.getFakeId(
    Order.SObjectType
  );
  private static final Id ORDER_TWO_ID = TestUtility.getFakeId(
    Order.SObjectType
  );

  @IsTest
  static void constructorTest() {
    Mock dmlMock = Mock.forType(IDMLExecutor.class);
    IDMLExecutor dml = (IDMLExecutor) dmlMock.stub;

    Assert.isNotNull(new QuoteToOrderDAO());
    Assert.isNotNull(new QuoteToOrderDAO(dml));
  }

  @IsTest
  static void saveOrdersTest() {
    Mock dmlMock = Mock.forType(IDMLExecutor.class);
    IDMLExecutor dml = (IDMLExecutor) dmlMock.stub;
    MethodSpy insertRecords = dmlMock.spyOn('insertRecords');
    insertRecords.whenCalledWith(Argument.any(), true)
      .thenReturn(successfulInserts());
    Order firstOrder = new Order(), secondOrder = new Order();
    OrderItem firstItem = new OrderItem(), secondItem = new OrderItem();
    Map<Id, Order> orders = new Map<Id, Order>{
      QUOTE_TWO_ID => secondOrder,
      QUOTE_ONE_ID => firstOrder
    };
    Map<Id, List<OrderItem>> items = new Map<Id, List<OrderItem>>{
      QUOTE_ONE_ID => new List<OrderItem>{ firstItem },
      QUOTE_TWO_ID => new List<OrderItem>{ secondItem }
    };

    QuoteToOrderDAO dao = new QuoteToOrderDAO(dml);
    Map<Id, Id> result = dao.saveOrders(orders, items);

    Assert.areEqual(ORDER_ONE_ID, result.get(QUOTE_ONE_ID));
    Assert.areEqual(ORDER_TWO_ID, result.get(QUOTE_TWO_ID));
    Assert.areEqual(ORDER_ONE_ID, firstItem.OrderId);
    Assert.areEqual(ORDER_TWO_ID, secondItem.OrderId);
    Expect.that(insertRecords).hasBeenCalledTimes(2);
  }

  @IsTest
  static void findQuotesTest() {
    QuoteToOrderDAO dao = new QuoteToOrderDAO();

    Test.startTest();
    // Governor usage proves the real query executed without constructing a full
    // graph merely to assert that Salesforce returns records just inserted.
    Integer queriesBefore = Limits.getQueries();
    Map<Id, Quote> quotesById = dao.findQuotes(new Set<Id>{ QUOTE_ONE_ID });
    Integer queriesAfter = Limits.getQueries();
    Test.stopTest();

    Assert.areEqual(queriesBefore + 1, queriesAfter);
    Assert.isTrue(quotesById.isEmpty());
  }

  @IsTest
  static void findQuoteLinesTest() {
    QuoteToOrderDAO dao = new QuoteToOrderDAO();

    Test.startTest();
    // The E2E suite owns field-level query compatibility; this unit test keeps
    // the DAO boundary visible while remaining inexpensive.
    Integer queriesBefore = Limits.getQueries();
    List<QuoteLineItem> quoteLines = dao.findQuoteLines(
      new Set<Id>{ QUOTE_ONE_ID }
    );
    Integer queriesAfter = Limits.getQueries();
    Test.stopTest();

    Assert.areEqual(queriesBefore + 1, queriesAfter);
    Assert.isTrue(quoteLines.isEmpty());
  }

  @IsTest
  static void markQuotesConvertedTest() {
    Mock dmlMock = Mock.forType(IDMLExecutor.class);
    IDMLExecutor dml = (IDMLExecutor) dmlMock.stub;
    MethodSpy updateRecords = dmlMock.spyOn('updateRecords');
    new QuoteToOrderDAO(dml)
      .markQuotesConverted(
        new Map<Id, Id>{
          QUOTE_TWO_ID => ORDER_TWO_ID,
          QUOTE_ONE_ID => ORDER_ONE_ID
        }
      );
    Expect.that(updateRecords)
      .hasBeenCalledWith(
        Argument.jsonEquals(
          new List<SObject>{
            new Quote(Id = QUOTE_ONE_ID, Converted_Order__c = ORDER_ONE_ID),
            new Quote(Id = QUOTE_TWO_ID, Converted_Order__c = ORDER_TWO_ID)
          }
        ),
        true
      );
  }

  private static Database.SaveResult[] successfulInserts() {
    return (Database.SaveResult[]) JSON.deserialize(
      '[{"id":"' +
        ORDER_ONE_ID +
        '","success":true,"errors":[]},{"id":"' +
        ORDER_TWO_ID +
        '","success":true,"errors":[]}]',
      List<Database.SaveResult>.class
    );
  }
}
