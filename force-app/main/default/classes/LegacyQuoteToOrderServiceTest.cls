@IsTest
/**
 * Data-heavy tests required by the legacy architecture.
 * Static dependencies cannot be substituted around the complete convert method,
 * so that method's scenarios cross real SOQL and DML boundaries. Extracted pure
 * helpers receive in-memory values directly and get the same best-case treatment
 * as the refactored helpers. Shared @TestSetup amortizes only the fixture DML that
 * the hardwired conversion path genuinely requires.
 */
private class LegacyQuoteToOrderServiceTest {

  private static final String ACCEPTED_TWO_LINES = 'Accepted Two Lines';
  private static final String ACCEPTED_ONE_LINE = 'Accepted One Line';
  private static final String DRAFT_ONE_LINE = 'Draft One Line';
  private static final Id QUOTE_ID = TestUtility.getFakeId(Quote.SObjectType);
  private static final Id QUOTE_TWO_ID = TestUtility.getFakeId(
    Quote.SObjectType
  );
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

  /**
   * Creates the minimal persisted graph required by convert and convertQuotes.
   * Salesforce gives each test method an isolated copy, avoiding repeated setup
   * DML while keeping pure-helper tests independent of this data.
   */
  @TestSetup
  static void setupData() {

    QuoteToOrderTestDataFactory.createQuote(ACCEPTED_TWO_LINES, 2, 'Accepted');
    QuoteToOrderTestDataFactory.createQuote(ACCEPTED_ONE_LINE, 1, 'Accepted');
    QuoteToOrderTestDataFactory.createQuote(DRAFT_ONE_LINE, 1, 'Draft');
  }

  /**
   * Verifies the transitional interface method delegates to the legacy static
   * conversion and returns the created Order and line count.
   */
  @IsTest
  static void convertQuotesTest() {

    Quote quoteRecord = quoteByName(ACCEPTED_ONE_LINE);

    QuoteToOrderResult result = new LegacyQuoteToOrderService()
      .convertQuotes(new Set<Id>{ quoteRecord.Id })
      .get(quoteRecord.Id);

    Assert.isNotNull(result.orderId);
    Assert.areEqual(1, result.orderItemCount);
  }

  /**
   * Verifies every convert branch in one method-oriented test: empty inputs,
   * missing IDs, mixed eligibility, bulk persistence, mapping, and Quote links.
   */
  @IsTest
  static void convertTest() {

    // Scenario: null and empty inputs return without querying or performing DML.
    Assert.areEqual(0, LegacyQuoteToOrderService.convert(null).size());
    Assert.areEqual(0, LegacyQuoteToOrderService.convert(new Set<Id>()).size());

    // Scenario: an ID not returned by the hardwired query is rejected.
    assertConversionError(
      new Set<Id>{ TestUtility.getFakeId(Quote.SObjectType) },
      'Quote does not exist'
    );

    Quote first = quoteByName(ACCEPTED_TWO_LINES);
    Quote second = quoteByName(ACCEPTED_ONE_LINE);
    Quote draft = quoteByName(DRAFT_ONE_LINE);
    Set<Id> quoteIds = new Set<Id>{ first.Id, second.Id, draft.Id };
    Set<Id> eligibleQuoteIds = new Set<Id>{ first.Id, second.Id };
    List<QuoteLineItem> sourceLines = [
      SELECT QuoteId, PricebookEntryId, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE QuoteId IN :eligibleQuoteIds
      ORDER BY QuoteId, UnitPrice
    ];

    // Scenario: one bulk call converts both eligible Quotes and ignores Draft.
    Test.startTest();
    Map<Id, QuoteToOrderResult> resultsByQuoteId = LegacyQuoteToOrderService.convert(
      quoteIds
    );
    Test.stopTest();

    Assert.areEqual(2, resultsByQuoteId.size());
    Assert.isTrue(resultsByQuoteId.containsKey(first.Id));
    Assert.isTrue(resultsByQuoteId.containsKey(second.Id));
    Assert.isFalse(resultsByQuoteId.containsKey(draft.Id));
    Set<Id> orderIds = new Set<Id>{
      resultsByQuoteId.get(first.Id).orderId,
      resultsByQuoteId.get(second.Id).orderId
    };
    Assert.areEqual(2, [SELECT COUNT() FROM Order WHERE Id IN :orderIds]);
    Assert.areEqual(
      3,
      [SELECT COUNT() FROM OrderItem WHERE OrderId IN :orderIds]
    );

    // Scenario: persisted records retain the required source mappings.
    List<Order> savedOrders = [
      SELECT AccountId, EffectiveDate, Pricebook2Id, Status
      FROM Order
      WHERE Id IN :orderIds
    ];
    for (Order savedOrder : savedOrders) {

      Assert.areEqual(Date.today(), savedOrder.EffectiveDate);
      Assert.areEqual(Test.getStandardPricebookId(), savedOrder.Pricebook2Id);
      Assert.areEqual('Draft', savedOrder.Status);
    }
    Map<String, OrderItem> savedItemsByValues = new Map<String, OrderItem>();
    for (OrderItem savedItem : [
      SELECT PricebookEntryId, Quantity, UnitPrice, OrderId
      FROM OrderItem
      WHERE OrderId IN :orderIds
    ]) {

      savedItemsByValues.put(
        savedItem.PricebookEntryId +
          ':' +
          savedItem.Quantity +
          ':' +
          savedItem.UnitPrice,
        savedItem
      );
    }
    for (QuoteLineItem sourceLine : sourceLines) {

      Assert.isTrue(
        savedItemsByValues.containsKey(
          sourceLine.PricebookEntryId +
            ':' +
            sourceLine.Quantity +
            ':' +
            sourceLine.UnitPrice
        )
      );
    }

    // Scenario: each converted Quote is linked to its corresponding Order.
    for (Quote convertedQuote : [
      SELECT Id, Converted_Order__c
      FROM Quote
      WHERE Id IN :eligibleQuoteIds
    ]) {

      Assert.areEqual(
        resultsByQuoteId.get(convertedQuote.Id).orderId,
        convertedQuote.Converted_Order__c
      );
    }
  }

  /** Verifies only Quotes matching the accepted status are selected. */
  @IsTest
  static void selectEligibleQuoteIdsTest() {

    Quote accepted = inMemoryQuote(QUOTE_ID, 'Accepted');
    Quote draft = inMemoryQuote(QUOTE_TWO_ID, 'Draft');

    Set<Id> result = LegacyQuoteToOrderService.selectEligibleQuoteIds(
      new Map<Id, Quote>{ accepted.Id => accepted, draft.Id => draft },
      'Accepted'
    );

    Assert.areEqual(new Set<Id>{ accepted.Id }, result);
  }

  /** Verifies in-memory Quote Lines are grouped by parent Quote ID. */
  @IsTest
  static void groupQuoteLinesTest() {

    List<QuoteLineItem> lines = inMemoryLines();

    Map<Id, List<QuoteLineItem>> result = LegacyQuoteToOrderService.groupQuoteLines(
      lines
    );

    Assert.areEqual(1, result.size());
    Assert.areEqual(2, result.get(QUOTE_ID).size());
  }

  /** Verifies validated Quotes are mapped to draft Orders without DML. */
  @IsTest
  static void buildOrdersTest() {

    Quote quoteRecord = inMemoryQuote(QUOTE_ID, 'Accepted');
    List<QuoteLineItem> lines = inMemoryLines();

    Order result = LegacyQuoteToOrderService.buildOrders(
        new Set<Id>{ QUOTE_ID },
        new Map<Id, Quote>{ QUOTE_ID => quoteRecord },
        new Map<Id, List<QuoteLineItem>>{ QUOTE_ID => lines },
        FIXED_DATE
      )
      .get(QUOTE_ID);

    Assert.areEqual(ACCOUNT_ID, result.AccountId);
    Assert.areEqual(FIXED_DATE, result.EffectiveDate);
    Assert.areEqual(PRICEBOOK_ID, result.Pricebook2Id);
    Assert.areEqual('Draft', result.Status);
  }

  /** Verifies Quote Lines are mapped to Order Items with the supplied Order ID. */
  @IsTest
  static void buildOrderItemsTest() {

    List<QuoteLineItem> lines = inMemoryLines();

    List<OrderItem> result = LegacyQuoteToOrderService.buildOrderItems(
        new Set<Id>{ QUOTE_ID },
        new Map<Id, List<QuoteLineItem>>{ QUOTE_ID => lines },
        new Map<Id, Id>{ QUOTE_ID => ORDER_ID }
      )
      .get(QUOTE_ID);

    Assert.areEqual(2, result.size());
    Assert.areEqual(ORDER_ID, result[0].OrderId);
    Assert.areEqual(lines[0].PricebookEntryId, result[0].PricebookEntryId);
    Assert.areEqual(lines[0].Quantity, result[0].Quantity);
    Assert.areEqual(lines[0].UnitPrice, result[0].UnitPrice);
  }

  /** Verifies Order IDs and item counts are mapped to conversion results. */
  @IsTest
  static void buildResultsTest() {

    QuoteToOrderResult result = LegacyQuoteToOrderService.buildResults(
        new Set<Id>{ QUOTE_ID },
        new Map<Id, Id>{ QUOTE_ID => ORDER_ID },
        new Map<Id, List<OrderItem>>{
          QUOTE_ID => new List<OrderItem>{ new OrderItem(), new OrderItem() }
        }
      )
      .get(QUOTE_ID);

    Assert.areEqual(ORDER_ID, result.orderId);
    Assert.areEqual(2, result.orderItemCount);
  }

  /** Verifies every validation branch directly with in-memory records. */
  @IsTest
  static void validateTest() {

    // Scenario: an existing conversion link prevents duplicate conversion.
    assertValidationError(
      inMemoryQuote(QUOTE_ID, 'Accepted', ORDER_ID, ACCOUNT_ID, PRICEBOOK_ID),
      inMemoryLines(),
      'Quote was already converted'
    );

    // Scenario: an Account is required to create the Order.
    assertValidationError(
      inMemoryQuote(QUOTE_ID, 'Accepted', null, null, PRICEBOOK_ID),
      inMemoryLines(),
      'Quote Account is required'
    );

    // Scenario: a Price Book is required to create compatible Order Items.
    assertValidationError(
      inMemoryQuote(QUOTE_ID, 'Accepted', null, ACCOUNT_ID, null),
      inMemoryLines(),
      'Quote Price Book is required'
    );

    // Scenario: at least one Quote Line is required.
    assertValidationError(
      inMemoryQuote(QUOTE_ID, 'Accepted'),
      new List<QuoteLineItem>(),
      'Quote must contain at least one line'
    );
  }

  private static Quote inMemoryQuote(Id quoteId, String status) {

    return inMemoryQuote(quoteId, status, null, ACCOUNT_ID, PRICEBOOK_ID);
  }

  private static Quote inMemoryQuote(
    Id quoteId,
    String status,
    Id convertedOrderId,
    Id accountId,
    Id pricebookId
  ) {

    return (Quote) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'Id' => quoteId,
          'Status' => status,
          'Converted_Order__c' => convertedOrderId,
          'AccountId' => accountId,
          'Pricebook2Id' => pricebookId
        }
      ),
      Quote.class
    );
  }

  private static List<QuoteLineItem> inMemoryLines() {

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

  private static Quote quoteByName(String quoteName) {

    return [
      SELECT Id, AccountId, Pricebook2Id, Status, Converted_Order__c
      FROM Quote
      WHERE Name = :quoteName
      LIMIT 1
    ];
  }

  private static void assertConversionError(
    Set<Id> quoteIds,
    String expectedMessage
  ) {

    try {

      LegacyQuoteToOrderService.convert(quoteIds);
      Assert.fail('Expected QuoteToOrderException');
    } catch (QuoteToOrderException error) {

      Assert.areEqual(expectedMessage, error.getMessage());
    }
  }

  private static void assertValidationError(
    Quote quoteRecord,
    List<QuoteLineItem> quoteLines,
    String expectedMessage
  ) {

    try {

      LegacyQuoteToOrderService.validate(quoteRecord, quoteLines);
      Assert.fail('Expected QuoteToOrderException');
    } catch (QuoteToOrderException error) {

      Assert.areEqual(expectedMessage, error.getMessage());
    }
  }
}
