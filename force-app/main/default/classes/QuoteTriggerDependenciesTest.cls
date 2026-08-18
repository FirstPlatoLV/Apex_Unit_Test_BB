@IsTest
/**
 * Verifies the production composition root.
 * These tests ensure both interface branches and the fully wired refactored graph
 * can be constructed; they complement isolated service tests.
 */
private class QuoteTriggerDependenciesTest {
  /** Verifies the composition root exposes the actual Default policy record. */
  @IsTest
  static void getPolicyTest() {

    Quote_Conversion_Policy__mdt actualPolicy = QuoteTriggerDependencies.getPolicy();

    Assert.areEqual(LegacyQuoteConversionPolicy.getPolicy(), actualPolicy);
  }

  /** Verifies the legacy branch is composed as the shared service interface. */
  @IsTest
  static void getLegacyServiceTest() {

    IQuoteToOrderService actualService = QuoteTriggerDependencies.getLegacyService();

    Assert.isTrue(actualService instanceof LegacyQuoteToOrderService);
  }

  /**
   * Verifies the complete refactored production graph can be composed and can
   * persist an Order, its item, and the Quote conversion link.
   */
  @IsTest
  static void getNewServiceTest() {

    QuoteToOrderTestDataFactory.Graph graph = QuoteToOrderTestDataFactory.createAcceptedQuote(
      1
    );

    QuoteToOrderResult result = QuoteTriggerDependencies.getNewService()
      .convertQuotes(new Set<Id>{ graph.quoteRecord.Id })
      .get(graph.quoteRecord.Id);

    Assert.isNotNull(result.orderId);
    Assert.areEqual(1, result.orderItemCount);
    Assert.areEqual(
      result.orderId,
      [SELECT Converted_Order__c FROM Quote WHERE Id = :graph.quoteRecord.Id]
      .Converted_Order__c
    );
  }
}
