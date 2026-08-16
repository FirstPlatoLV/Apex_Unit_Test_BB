@IsTest
/**
 * Data-heavy tests required by the legacy architecture.
 * Static dependencies cannot be substituted, so every business scenario crosses
 * real SOQL and DML boundaries. This gives confidence but increases runtime and
 * makes failures less isolated. Shared @TestSetup data keeps the comparison fair
 * by amortizing unavoidable fixture DML across the class; each test still invokes
 * the real legacy dependencies relevant to its scenario.
 */
private class LegacyQuoteToOrderServiceTest {
  private static final String ACCEPTED_TWO_LINES = 'Accepted Two Lines';
  private static final String ACCEPTED_ONE_LINE = 'Accepted One Line';
  private static final String DRAFT_ONE_LINE = 'Draft One Line';
  private static final String ALREADY_CONVERTED = 'Already Converted';
  private static final String NO_LINES = 'No Lines';
  private static final String NO_ACCOUNT = 'No Account';
  private static final String NO_PRICE_BOOK = 'No Price Book';

  /**
   * Creates every persisted scenario once for the class. Salesforce gives each
   * test method an isolated copy, so methods can query and mutate these records
   * without leaking state while avoiding repeated setup DML.
   */
  @TestSetup
  static void setupData() {
    QuoteToOrderTestDataFactory.createQuote(ACCEPTED_TWO_LINES, 2, 'Accepted');
    QuoteToOrderTestDataFactory.createQuote(ACCEPTED_ONE_LINE, 1, 'Accepted');
    QuoteToOrderTestDataFactory.createQuote(DRAFT_ONE_LINE, 1, 'Draft');
    QuoteToOrderTestDataFactory.Graph converted = QuoteToOrderTestDataFactory.createQuote(
      ALREADY_CONVERTED,
      1,
      'Accepted'
    );
    QuoteToOrderTestDataFactory.createQuote(NO_LINES, 0, 'Accepted');

    Order existingOrder = new Order(
      AccountId = converted.account.Id,
      EffectiveDate = Date.today(),
      Pricebook2Id = Test.getStandardPricebookId(),
      Status = 'Draft'
    );
    insert existingOrder;
    converted.quoteRecord.Converted_Order__c = existingOrder.Id;
    update converted.quoteRecord;

    Opportunity accountlessOpportunity = new Opportunity(
      Name = NO_ACCOUNT + ' Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert accountlessOpportunity;
    insert new Quote(
      Name = NO_ACCOUNT,
      OpportunityId = accountlessOpportunity.Id,
      Pricebook2Id = Test.getStandardPricebookId(),
      Status = 'Accepted'
    );

    Account noPriceBookAccount = new Account(Name = NO_PRICE_BOOK + ' Account');
    insert noPriceBookAccount;
    Opportunity noPriceBookOpportunity = new Opportunity(
      Name = NO_PRICE_BOOK + ' Opportunity',
      AccountId = noPriceBookAccount.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30)
    );
    insert noPriceBookOpportunity;
    insert new Quote(
      Name = NO_PRICE_BOOK,
      OpportunityId = noPriceBookOpportunity.Id,
      Status = 'Accepted'
    );
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

  /** Verifies null and empty bulk inputs return an empty result without work. */
  @IsTest
  static void nullAndEmptyInputTest() {
    Assert.areEqual(0, LegacyQuoteToOrderService.convert(null).size());
    Assert.areEqual(0, LegacyQuoteToOrderService.convert(new Set<Id>()).size());
  }

  /** Verifies an ID not returned by the legacy query raises the expected error. */
  @IsTest
  static void unknownQuoteTest() {
    assertConversionError(
      new Set<Id>{ TestUtility.getFakeId(Quote.SObjectType) },
      'Quote does not exist'
    );
  }

  /** Verifies a Quote linked to an existing Order cannot be converted again. */
  @IsTest
  static void alreadyConvertedQuoteTest() {
    Quote quoteRecord = quoteByName(ALREADY_CONVERTED);

    assertConversionError(
      new Set<Id>{ quoteRecord.Id },
      'Quote was already converted'
    );
  }

  /** Verifies an eligible Quote without an Account is rejected before DML. */
  @IsTest
  static void quoteWithoutAccountTest() {
    Quote quoteRecord = quoteByName(NO_ACCOUNT);

    assertConversionError(
      new Set<Id>{ quoteRecord.Id },
      'Quote Account is required'
    );
  }

  /** Verifies an eligible Quote without a Price Book is rejected before DML. */
  @IsTest
  static void quoteWithoutPriceBookTest() {
    Quote quoteRecord = quoteByName(NO_PRICE_BOOK);

    assertConversionError(
      new Set<Id>{ quoteRecord.Id },
      'Quote Price Book is required'
    );
  }

  /** Verifies an eligible Quote without lines is rejected before Order DML. */
  @IsTest
  static void quoteWithoutLinesTest() {
    Quote quoteRecord = quoteByName(NO_LINES);

    assertConversionError(
      new Set<Id>{ quoteRecord.Id },
      'Quote must contain at least one line'
    );
  }

  /**
   * Verifies the complete legacy mapping and persistence path: Order fields,
   * Order Items, the result contract, and the Quote conversion link.
   */
  @IsTest
  static void acceptedQuoteCreatesOrderAndLines() {
    Quote quoteRecord = quoteByName(ACCEPTED_TWO_LINES);
    List<QuoteLineItem> sourceLines = [
      SELECT PricebookEntryId, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE QuoteId = :quoteRecord.Id
      ORDER BY UnitPrice
    ];

    Test.startTest();
    QuoteToOrderResult result = LegacyQuoteToOrderService.convert(
        new Set<Id>{ quoteRecord.Id }
      )
      .get(quoteRecord.Id);
    Test.stopTest();
    Id orderId = result.orderId;

    Order savedOrder = [
      SELECT AccountId, EffectiveDate, Pricebook2Id, Status
      FROM Order
      WHERE Id = :orderId
    ];
    List<OrderItem> savedItems = [
      SELECT PricebookEntryId, Quantity, UnitPrice
      FROM OrderItem
      WHERE OrderId = :orderId
      ORDER BY UnitPrice
    ];
    Quote savedQuote = [
      SELECT Converted_Order__c
      FROM Quote
      WHERE Id = :quoteRecord.Id
    ];
    Assert.areEqual(quoteRecord.AccountId, savedOrder.AccountId);
    Assert.areEqual(Date.today(), savedOrder.EffectiveDate);
    Assert.areEqual(Test.getStandardPricebookId(), savedOrder.Pricebook2Id);
    Assert.areEqual('Draft', savedOrder.Status);
    Assert.areEqual(2, savedItems.size());
    Assert.areEqual(
      sourceLines[0].PricebookEntryId,
      savedItems[0].PricebookEntryId
    );
    Assert.areEqual(sourceLines[0].Quantity, savedItems[0].Quantity);
    Assert.areEqual(sourceLines[0].UnitPrice, savedItems[0].UnitPrice);
    Assert.areEqual(
      sourceLines[1].PricebookEntryId,
      savedItems[1].PricebookEntryId
    );
    Assert.areEqual(sourceLines[1].Quantity, savedItems[1].Quantity);
    Assert.areEqual(sourceLines[1].UnitPrice, savedItems[1].UnitPrice);
    Assert.areEqual(2, result.orderItemCount);
    Assert.areEqual(orderId, savedQuote.Converted_Order__c);
  }

  /** Verifies a Quote outside the configured status is silently ignored. */
  @IsTest
  static void nonAcceptedQuoteIsIgnored() {
    Quote quoteRecord = quoteByName(DRAFT_ONE_LINE);

    Assert.isFalse(
      LegacyQuoteToOrderService.convert(new Set<Id>{ quoteRecord.Id })
        .containsKey(quoteRecord.Id)
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Order WHERE AccountId = :quoteRecord.AccountId]
    );
  }

  /**
   * Verifies multiple Quotes and lines are converted in one bulk invocation and
   * each Quote is linked to its corresponding persisted Order.
   */
  @IsTest
  static void convertsMultipleQuotesWithBulkQueriesAndDml() {
    Quote first = quoteByName(ACCEPTED_TWO_LINES);
    Quote second = quoteByName(ACCEPTED_ONE_LINE);
    Set<Id> quoteIds = new Set<Id>{ first.Id, second.Id };

    Test.startTest();
    Map<Id, QuoteToOrderResult> resultsByQuoteId = LegacyQuoteToOrderService.convert(
      quoteIds
    );
    Test.stopTest();

    Assert.areEqual(2, resultsByQuoteId.size());
    Set<Id> orderIds = new Set<Id>{
      resultsByQuoteId.get(first.Id).orderId,
      resultsByQuoteId.get(second.Id).orderId
    };
    Assert.areEqual(2, [SELECT COUNT() FROM Order WHERE Id IN :orderIds]);
    Assert.areEqual(
      3,
      [SELECT COUNT() FROM OrderItem WHERE OrderId IN :orderIds]
    );
    for (Quote convertedQuote : [
      SELECT Id, Converted_Order__c
      FROM Quote
      WHERE Id IN :quoteIds
    ]) {
      Assert.areEqual(
        resultsByQuoteId.get(convertedQuote.Id).orderId,
        convertedQuote.Converted_Order__c
      );
    }
  }

  /** Verifies a mixed batch converts only eligible Quotes. */
  @IsTest
  static void mixedEligibilityTest() {
    Quote accepted = quoteByName(ACCEPTED_ONE_LINE);
    Quote draft = quoteByName(DRAFT_ONE_LINE);

    Map<Id, QuoteToOrderResult> resultsByQuoteId = LegacyQuoteToOrderService.convert(
      new Set<Id>{ accepted.Id, draft.Id }
    );

    Assert.areEqual(1, resultsByQuoteId.size());
    Assert.isTrue(resultsByQuoteId.containsKey(accepted.Id));
    Assert.isFalse(resultsByQuoteId.containsKey(draft.Id));
  }

  /** Verifies only Quotes matching the accepted status are selected. */
  @IsTest
  static void selectEligibleQuoteIdsTest() {
    Quote accepted = quoteByName(ACCEPTED_ONE_LINE);
    Quote draft = quoteByName(DRAFT_ONE_LINE);

    Set<Id> result = LegacyQuoteToOrderService.selectEligibleQuoteIds(
      new Map<Id, Quote>{ accepted.Id => accepted, draft.Id => draft },
      'Accepted'
    );

    Assert.areEqual(new Set<Id>{ accepted.Id }, result);
  }

  /** Verifies queried Quote Lines are grouped by parent Quote ID. */
  @IsTest
  static void groupQuoteLinesTest() {
    Quote quoteRecord = quoteByName(ACCEPTED_TWO_LINES);
    List<QuoteLineItem> lines = [
      SELECT QuoteId, PricebookEntryId, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE QuoteId = :quoteRecord.Id
    ];

    Map<Id, List<QuoteLineItem>> result = LegacyQuoteToOrderService.groupQuoteLines(
      lines
    );

    Assert.areEqual(1, result.size());
    Assert.areEqual(2, result.get(quoteRecord.Id).size());
  }

  /** Verifies validated Quotes are mapped to draft Orders without DML. */
  @IsTest
  static void buildOrdersTest() {
    Quote quoteRecord = quoteByName(ACCEPTED_ONE_LINE);
    List<QuoteLineItem> lines = [
      SELECT QuoteId, PricebookEntryId, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE QuoteId = :quoteRecord.Id
    ];
    Date effectiveDate = Date.newInstance(2030, 4, 15);

    Order result = LegacyQuoteToOrderService.buildOrders(
        new Set<Id>{ quoteRecord.Id },
        new Map<Id, Quote>{ quoteRecord.Id => quoteRecord },
        new Map<Id, List<QuoteLineItem>>{ quoteRecord.Id => lines },
        effectiveDate
      )
      .get(quoteRecord.Id);

    Assert.areEqual(quoteRecord.AccountId, result.AccountId);
    Assert.areEqual(effectiveDate, result.EffectiveDate);
    Assert.areEqual(quoteRecord.Pricebook2Id, result.Pricebook2Id);
    Assert.areEqual('Draft', result.Status);
  }

  /** Verifies Quote Lines are mapped to Order Items with the supplied Order ID. */
  @IsTest
  static void buildOrderItemsTest() {
    Quote quoteRecord = quoteByName(ACCEPTED_ONE_LINE);
    List<QuoteLineItem> lines = [
      SELECT QuoteId, PricebookEntryId, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE QuoteId = :quoteRecord.Id
    ];
    Id orderId = TestUtility.getFakeId(Order.SObjectType);

    List<OrderItem> result = LegacyQuoteToOrderService.buildOrderItems(
        new Set<Id>{ quoteRecord.Id },
        new Map<Id, List<QuoteLineItem>>{ quoteRecord.Id => lines },
        new Map<Id, Id>{ quoteRecord.Id => orderId }
      )
      .get(quoteRecord.Id);

    Assert.areEqual(1, result.size());
    Assert.areEqual(orderId, result[0].OrderId);
    Assert.areEqual(lines[0].PricebookEntryId, result[0].PricebookEntryId);
    Assert.areEqual(lines[0].Quantity, result[0].Quantity);
    Assert.areEqual(lines[0].UnitPrice, result[0].UnitPrice);
  }

  /** Verifies Order IDs and item counts are mapped to conversion results. */
  @IsTest
  static void buildResultsTest() {
    Quote quoteRecord = quoteByName(ACCEPTED_ONE_LINE);
    Id orderId = TestUtility.getFakeId(Order.SObjectType);

    QuoteToOrderResult result = LegacyQuoteToOrderService.buildResults(
        new Set<Id>{ quoteRecord.Id },
        new Map<Id, Id>{ quoteRecord.Id => orderId },
        new Map<Id, List<OrderItem>>{
          quoteRecord.Id => new List<OrderItem>{ new OrderItem() }
        }
      )
      .get(quoteRecord.Id);

    Assert.areEqual(orderId, result.orderId);
    Assert.areEqual(1, result.orderItemCount);
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
}
