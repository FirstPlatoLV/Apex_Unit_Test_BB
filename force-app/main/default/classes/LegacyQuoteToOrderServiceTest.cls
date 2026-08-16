@IsTest
/**
 * Data-heavy tests required by the legacy architecture.
 * Static dependencies cannot be substituted, so every business scenario crosses
 * real SOQL and DML boundaries. This gives confidence but increases runtime and
 * makes failures less isolated.
 */
private class LegacyQuoteToOrderServiceTest {
  /**
   * Verifies the transitional interface method delegates to the legacy static
   * conversion and returns the created Order and line count.
   */
  @IsTest
  static void convertQuotesTest() {
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );

    QuoteToOrderResult result = new LegacyQuoteToOrderService()
      .convertQuotes(new Set<Id>{ graph.quoteRecord.Id })
      .get(graph.quoteRecord.Id);

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
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );
    Order existingOrder = new Order(
      AccountId = graph.account.Id,
      EffectiveDate = Date.today(),
      Pricebook2Id = Test.getStandardPricebookId(),
      Status = 'Draft'
    );
    insert existingOrder;
    graph.quoteRecord.Converted_Order__c = existingOrder.Id;
    update graph.quoteRecord;

    assertConversionError(
      new Set<Id>{ graph.quoteRecord.Id },
      'Quote was already converted'
    );
  }

  /** Verifies an eligible Quote without an Account is rejected before DML. */
  @IsTest
  static void quoteWithoutAccountTest() {
    Opportunity opportunity = new Opportunity(
      Name = 'Accountless Opportunity',
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert opportunity;
    Quote quoteRecord = new Quote(
      Name = 'Accountless Quote',
      OpportunityId = opportunity.Id,
      Pricebook2Id = Test.getStandardPricebookId(),
      Status = LegacyQuoteConversionPolicy.getPolicy().Accepted_Quote_Status__c
    );
    insert quoteRecord;

    assertConversionError(
      new Set<Id>{ quoteRecord.Id },
      'Quote Account is required'
    );
  }

  /** Verifies an eligible Quote without a Price Book is rejected before DML. */
  @IsTest
  static void quoteWithoutPriceBookTest() {
    Account accountRecord = new Account(Name = 'No Price Book Account');
    insert accountRecord;
    Opportunity opportunity = new Opportunity(
      Name = 'No Price Book Opportunity',
      AccountId = accountRecord.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30)
    );
    insert opportunity;
    Quote quoteRecord = new Quote(
      Name = 'No Price Book Quote',
      OpportunityId = opportunity.Id,
      Status = LegacyQuoteConversionPolicy.getPolicy().Accepted_Quote_Status__c
    );
    insert quoteRecord;

    assertConversionError(
      new Set<Id>{ quoteRecord.Id },
      'Quote Price Book is required'
    );
  }

  /** Verifies an eligible Quote without lines is rejected before Order DML. */
  @IsTest
  static void quoteWithoutLinesTest() {
    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      0
    );

    assertConversionError(
      new Set<Id>{ graph.quoteRecord.Id },
      'Quote must contain at least one line'
    );
  }

  /**
   * Verifies the complete legacy mapping and persistence path: Order fields,
   * Order Items, the result contract, and the Quote conversion link.
   */
  @IsTest
  static void acceptedQuoteCreatesOrderAndLines() {
    Account accountRecord = new Account(Name = 'Brown-bag Account');
    insert accountRecord;

    Opportunity opportunity = new Opportunity(
      Name = 'Brown-bag Opportunity',
      AccountId = accountRecord.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30),
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert opportunity;

    List<Product2> products = new List<Product2>{
      new Product2(Name = 'Brown-bag Product A', IsActive = true),
      new Product2(Name = 'Brown-bag Product B', IsActive = true)
    };
    insert products;

    List<PricebookEntry> entries = new List<PricebookEntry>{
      new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = products[0].Id,
        UnitPrice = 10,
        IsActive = true
      ),
      new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = products[1].Id,
        UnitPrice = 25,
        IsActive = true
      )
    };
    insert entries;

    Quote quoteRecord = new Quote(
      Name = 'Brown-bag Quote',
      OpportunityId = opportunity.Id,
      Pricebook2Id = Test.getStandardPricebookId(),
      Status = 'Accepted'
    );
    insert quoteRecord;
    insert new List<QuoteLineItem>{
      new QuoteLineItem(
        QuoteId = quoteRecord.Id,
        PricebookEntryId = entries[0].Id,
        Quantity = 2,
        UnitPrice = 9
      ),
      new QuoteLineItem(
        QuoteId = quoteRecord.Id,
        PricebookEntryId = entries[1].Id,
        Quantity = 3,
        UnitPrice = 24
      )
    };

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
    Assert.areEqual(accountRecord.Id, savedOrder.AccountId);
    Assert.areEqual(Date.today(), savedOrder.EffectiveDate);
    Assert.areEqual(Test.getStandardPricebookId(), savedOrder.Pricebook2Id);
    Assert.areEqual('Draft', savedOrder.Status);
    Assert.areEqual(2, savedItems.size());
    Assert.areEqual(entries[0].Id, savedItems[0].PricebookEntryId);
    Assert.areEqual(Decimal.valueOf(2), savedItems[0].Quantity);
    Assert.areEqual(Decimal.valueOf(9), savedItems[0].UnitPrice);
    Assert.areEqual(entries[1].Id, savedItems[1].PricebookEntryId);
    Assert.areEqual(Decimal.valueOf(3), savedItems[1].Quantity);
    Assert.areEqual(Decimal.valueOf(24), savedItems[1].UnitPrice);
    Assert.areEqual(2, result.orderItemCount);
    Assert.areEqual(orderId, savedQuote.Converted_Order__c);
  }

  /** Verifies a Quote outside the configured status is silently ignored. */
  @IsTest
  static void nonAcceptedQuoteIsIgnored() {
    Account accountRecord = new Account(Name = 'Rejected Account');
    insert accountRecord;
    Opportunity opportunity = new Opportunity(
      Name = 'Rejected Opportunity',
      AccountId = accountRecord.Id,
      StageName = 'Prospecting',
      CloseDate = Date.today().addDays(30)
    );
    insert opportunity;
    Quote quoteRecord = new Quote(
      Name = 'Draft Quote',
      OpportunityId = opportunity.Id,
      Status = 'Draft'
    );
    insert quoteRecord;

    Assert.isFalse(
      LegacyQuoteToOrderService.convert(new Set<Id>{ quoteRecord.Id })
        .containsKey(quoteRecord.Id)
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Order WHERE AccountId = :accountRecord.Id]
    );
  }

  /**
   * Verifies multiple Quotes and lines are converted in one bulk invocation and
   * each Quote is linked to its corresponding persisted Order.
   */
  @IsTest
  static void convertsMultipleQuotesWithBulkQueriesAndDml() {
    QuoteToOrderTestDataFactory.Graph first = QuoteToOrderTestDataFactory.createAcceptedQuote(
      2
    );
    QuoteToOrderTestDataFactory.Graph second = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );
    Set<Id> quoteIds = new Set<Id>{
      first.quoteRecord.Id,
      second.quoteRecord.Id
    };

    Test.startTest();
    Map<Id, QuoteToOrderResult> resultsByQuoteId = LegacyQuoteToOrderService.convert(
      quoteIds
    );
    Test.stopTest();

    Assert.areEqual(2, resultsByQuoteId.size());
    Set<Id> orderIds = new Set<Id>{
      resultsByQuoteId.get(first.quoteRecord.Id).orderId,
      resultsByQuoteId.get(second.quoteRecord.Id).orderId
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
    QuoteToOrderTestDataFactory.Graph accepted = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );
    QuoteToOrderTestDataFactory.Graph draft = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );
    draft.quoteRecord.Status = 'Draft';
    update draft.quoteRecord;

    Map<Id, QuoteToOrderResult> resultsByQuoteId = LegacyQuoteToOrderService.convert(
      new Set<Id>{ accepted.quoteRecord.Id, draft.quoteRecord.Id }
    );

    Assert.areEqual(1, resultsByQuoteId.size());
    Assert.isTrue(resultsByQuoteId.containsKey(accepted.quoteRecord.Id));
    Assert.isFalse(resultsByQuoteId.containsKey(draft.quoteRecord.Id));
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
