@IsTest
/**
 * Unmocked positive and negative E2E tests for the complete trigger path.
 * They read the org's actual metadata flag, so the same assertions validate the
 * legacy or refactored implementation after an administrator changes the flag.
 *
 * During migration, keep the existing E2E suite even when it is large or slow:
 * it is the behavioral safety net proving the refactored implementation still
 * satisfies established business journeys. After parity is demonstrated and
 * each rule is covered by isolated unit tests, redundant E2E scenarios can be
 * reduced. Retain a small set of critical journeys to verify production wiring.
 */
private class QuoteTriggerTest {
  /**
   * Verifies an eligible status transition runs the complete metadata-selected
   * trigger path and persists an Order with every expected Order Item.
   */
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

  /**
   * Verifies a transition to an ineligible status runs no conversion, leaving
   * the Quote unlinked and creating no Order.
   */
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
