/**
 * Tightly coupled implementation retained to demonstrate an incremental
 * migration path. Business rules are mixed with mapping, Date.today(), static
 * DAO calls, static policy access, and persistence orchestration.
 *
 * The original static convert method remains available to existing callers.
 * Implementing IQuoteToOrderService is the transitional step: new orchestration
 * can depend on an abstraction before the internals are fully refactored.
 */
public inherited sharing class LegacyQuoteToOrderService implements IQuoteToOrderService {
  /** Delegates the interface contract to the existing static entry point. */
  public Map<Id, QuoteToOrderResult> convertQuotes(Set<Id> quoteIds) {
    return LegacyQuoteToOrderService.convert(quoteIds);
  }

  public static Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds) {
    if (quoteIds == null || quoteIds.isEmpty()) {
      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, Quote> quotesById = LegacyQuoteToOrderDAO.findQuotes(quoteIds);
    if (quotesById.size() != quoteIds.size()) {
      throw new QuoteToOrderException('Quote does not exist');
    }
    // Static policy access is convenient in production but cannot be replaced
    // with a test double inside this method.
    Quote_Conversion_Policy__mdt policy = LegacyQuoteConversionPolicy.getPolicy();
    String acceptedStatus = policy?.Accepted_Quote_Status__c;
    Set<Id> eligibleQuoteIds = new Set<Id>();
    for (Id quoteId : quoteIds) {
      if (quotesById.get(quoteId).Status == acceptedStatus) {
        eligibleQuoteIds.add(quoteId);
      }
    }
    if (eligibleQuoteIds.isEmpty()) {
      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, List<QuoteLineItem>> linesByQuoteId = new Map<Id, List<QuoteLineItem>>();
    for (
      QuoteLineItem quoteLine : LegacyQuoteToOrderDAO.findQuoteLines(
        eligibleQuoteIds
      )
    ) {
      if (!linesByQuoteId.containsKey(quoteLine.QuoteId)) {
        linesByQuoteId.put(quoteLine.QuoteId, new List<QuoteLineItem>());
      }
      linesByQuoteId.get(quoteLine.QuoteId).add(quoteLine);
    }
    // Stable ordering is required because inserted Orders are matched back to
    // Quotes by list index after Salesforce assigns the Order IDs.
    List<Id> orderedQuoteIds = new List<Id>(eligibleQuoteIds);
    orderedQuoteIds.sort();
    List<Order> orders = new List<Order>();
    for (Id currentQuoteId : orderedQuoteIds) {
      Quote quoteRecord = quotesById.get(currentQuoteId);
      validate(quoteRecord, linesByQuoteId.get(currentQuoteId));
      orders.add(
        new Order(
          AccountId = quoteRecord.AccountId,
          // The system clock is another hardwired dependency in the legacy path.
          EffectiveDate = Date.today(),
          Pricebook2Id = quoteRecord.Pricebook2Id,
          Status = 'Draft'
        )
      );
    }
    LegacyQuoteToOrderDAO.insertOrders(orders);

    List<OrderItem> orderItems = new List<OrderItem>();
    Map<Id, Id> orderIdsByQuoteId = new Map<Id, Id>();
    for (Integer index = 0; index < orderedQuoteIds.size(); index++) {
      Id currentQuoteId = orderedQuoteIds[index];
      orderIdsByQuoteId.put(currentQuoteId, orders[index].Id);
      for (QuoteLineItem quoteLine : linesByQuoteId.get(currentQuoteId)) {
        orderItems.add(
          new OrderItem(
            OrderId = orders[index].Id,
            PricebookEntryId = quoteLine.PricebookEntryId,
            Quantity = quoteLine.Quantity,
            UnitPrice = quoteLine.UnitPrice
          )
        );
      }
    }
    LegacyQuoteToOrderDAO.insertOrderItems(orderItems);
    LegacyQuoteToOrderDAO.markQuotesConverted(orderIdsByQuoteId);
    Map<Id, QuoteToOrderResult> results = new Map<Id, QuoteToOrderResult>();
    for (Id quoteId : orderedQuoteIds) {
      results.put(
        quoteId,
        new QuoteToOrderResult(
          orderIdsByQuoteId.get(quoteId),
          linesByQuoteId.get(quoteId).size()
        )
      );
    }
    return results;
  }

  private static void validate(
    Quote quoteRecord,
    List<QuoteLineItem> quoteLines
  ) {
    if (quoteRecord.Converted_Order__c != null) {
      throw new QuoteToOrderException('Quote was already converted');
    }
    if (quoteRecord.AccountId == null) {
      throw new QuoteToOrderException('Quote Account is required');
    }
    if (quoteRecord.Pricebook2Id == null) {
      throw new QuoteToOrderException('Quote Price Book is required');
    }
    if (quoteLines == null || quoteLines.isEmpty()) {
      throw new QuoteToOrderException('Quote must contain at least one line');
    }
  }
}
