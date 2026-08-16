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
    Set<Id> eligibleQuoteIds = selectEligibleQuoteIds(
      quotesById,
      acceptedStatus
    );
    if (eligibleQuoteIds.isEmpty()) {
      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, List<QuoteLineItem>> linesByQuoteId = groupQuoteLines(
      LegacyQuoteToOrderDAO.findQuoteLines(eligibleQuoteIds)
    );
    // Stable ordering is required because inserted Orders are matched back to
    // Quotes by list index after Salesforce assigns the Order IDs.
    List<Id> orderedQuoteIds = new List<Id>(eligibleQuoteIds);
    orderedQuoteIds.sort();
    Map<Id, Order> ordersByQuoteId = buildOrders(
      eligibleQuoteIds,
      quotesById,
      linesByQuoteId,
      Date.today()
    );
    List<Order> orders = new List<Order>();
    for (Id quoteId : orderedQuoteIds) {
      orders.add(ordersByQuoteId.get(quoteId));
    }
    // The legacy implementation performs straightforward DML directly. There
    // is no useful abstraction in a static helper that only forwards an insert.
    insert orders;

    Map<Id, Id> orderIdsByQuoteId = new Map<Id, Id>();
    for (Integer index = 0; index < orderedQuoteIds.size(); index++) {
      orderIdsByQuoteId.put(orderedQuoteIds[index], orders[index].Id);
    }
    Map<Id, List<OrderItem>> itemsByQuoteId = buildOrderItems(
      eligibleQuoteIds,
      linesByQuoteId,
      orderIdsByQuoteId
    );
    List<OrderItem> orderItems = new List<OrderItem>();
    for (Id quoteId : orderedQuoteIds) {
      orderItems.addAll(itemsByQuoteId.get(quoteId));
    }
    insert orderItems;
    LegacyQuoteToOrderDAO.markQuotesConverted(orderIdsByQuoteId);
    return buildResults(eligibleQuoteIds, orderIdsByQuoteId, itemsByQuoteId);
  }

  @TestVisible
  private static Set<Id> selectEligibleQuoteIds(
    Map<Id, Quote> quotesById,
    String acceptedQuoteStatus
  ) {
    Set<Id> eligibleQuoteIds = new Set<Id>();
    for (Id quoteId : quotesById.keySet()) {
      if (quotesById.get(quoteId).Status == acceptedQuoteStatus) {
        eligibleQuoteIds.add(quoteId);
      }
    }
    return eligibleQuoteIds;
  }

  @TestVisible
  private static Map<Id, List<QuoteLineItem>> groupQuoteLines(
    List<QuoteLineItem> quoteLines
  ) {
    Map<Id, List<QuoteLineItem>> linesByQuoteId = new Map<Id, List<QuoteLineItem>>();
    for (QuoteLineItem line : quoteLines) {
      if (!linesByQuoteId.containsKey(line.QuoteId)) {
        linesByQuoteId.put(line.QuoteId, new List<QuoteLineItem>());
      }
      linesByQuoteId.get(line.QuoteId).add(line);
    }
    return linesByQuoteId;
  }

  @TestVisible
  private static Map<Id, Order> buildOrders(
    Set<Id> quoteIds,
    Map<Id, Quote> quotesById,
    Map<Id, List<QuoteLineItem>> linesByQuoteId,
    Date effectiveDate
  ) {
    Map<Id, Order> ordersByQuoteId = new Map<Id, Order>();
    for (Id quoteId : quoteIds) {
      Quote quoteRecord = quotesById.get(quoteId);
      validate(quoteRecord, linesByQuoteId.get(quoteId));
      ordersByQuoteId.put(
        quoteId,
        new Order(
          AccountId = quoteRecord.AccountId,
          EffectiveDate = effectiveDate,
          Pricebook2Id = quoteRecord.Pricebook2Id,
          Status = 'Draft'
        )
      );
    }
    return ordersByQuoteId;
  }

  @TestVisible
  private static Map<Id, List<OrderItem>> buildOrderItems(
    Set<Id> quoteIds,
    Map<Id, List<QuoteLineItem>> linesByQuoteId,
    Map<Id, Id> orderIdsByQuoteId
  ) {
    Map<Id, List<OrderItem>> itemsByQuoteId = new Map<Id, List<OrderItem>>();
    for (Id quoteId : quoteIds) {
      List<OrderItem> items = new List<OrderItem>();
      for (QuoteLineItem line : linesByQuoteId.get(quoteId)) {
        items.add(
          new OrderItem(
            OrderId = orderIdsByQuoteId.get(quoteId),
            PricebookEntryId = line.PricebookEntryId,
            Quantity = line.Quantity,
            UnitPrice = line.UnitPrice
          )
        );
      }
      itemsByQuoteId.put(quoteId, items);
    }
    return itemsByQuoteId;
  }

  @TestVisible
  private static Map<Id, QuoteToOrderResult> buildResults(
    Set<Id> quoteIds,
    Map<Id, Id> orderIdsByQuoteId,
    Map<Id, List<OrderItem>> itemsByQuoteId
  ) {
    Map<Id, QuoteToOrderResult> results = new Map<Id, QuoteToOrderResult>();
    for (Id quoteId : quoteIds) {
      results.put(
        quoteId,
        new QuoteToOrderResult(
          orderIdsByQuoteId.get(quoteId),
          itemsByQuoteId.get(quoteId).size()
        )
      );
    }
    return results;
  }

  @TestVisible
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
