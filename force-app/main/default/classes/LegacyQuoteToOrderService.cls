public inherited sharing class LegacyQuoteToOrderService {
  public static Id convert(Id quoteId) {
    return convert(new Set<Id>{ quoteId }).get(quoteId);
  }

  public static Map<Id, Id> convert(Set<Id> quoteIds) {
    if (quoteIds == null || quoteIds.isEmpty()) {
      return new Map<Id, Id>();
    }
    Map<Id, Quote> quotesById = LegacyQuoteToOrderDAO.findQuotes(quoteIds);
    if (quotesById.size() != quoteIds.size()) {
      throw new QuoteToOrderException('Quote does not exist');
    }
    Map<Id, List<QuoteLineItem>> linesByQuoteId = new Map<Id, List<QuoteLineItem>>();
    for (
      QuoteLineItem quoteLine : LegacyQuoteToOrderDAO.findQuoteLines(quoteIds)
    ) {
      if (!linesByQuoteId.containsKey(quoteLine.QuoteId)) {
        linesByQuoteId.put(quoteLine.QuoteId, new List<QuoteLineItem>());
      }
      linesByQuoteId.get(quoteLine.QuoteId).add(quoteLine);
    }

    String acceptedStatus = BrownbagDemoPolicy.acceptedQuoteStatus();
    List<Id> orderedQuoteIds = new List<Id>(quoteIds);
    orderedQuoteIds.sort();
    List<Order> orders = new List<Order>();
    for (Id currentQuoteId : orderedQuoteIds) {
      Quote quoteRecord = quotesById.get(currentQuoteId);
      validate(quoteRecord, linesByQuoteId.get(currentQuoteId), acceptedStatus);
      orders.add(
        new Order(
          AccountId = quoteRecord.AccountId,
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
    return orderIdsByQuoteId;
  }

  private static void validate(
    Quote quoteRecord,
    List<QuoteLineItem> quoteLines,
    String acceptedStatus
  ) {
    if (quoteRecord.Status != acceptedStatus) {
      throw new QuoteToOrderException('Quote status is not accepted');
    }
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
