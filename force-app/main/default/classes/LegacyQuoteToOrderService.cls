public inherited sharing class LegacyQuoteToOrderService {
  public static Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds) {
    if (quoteIds == null || quoteIds.isEmpty()) {
      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, Quote> quotesById = LegacyQuoteToOrderDAO.findQuotes(quoteIds);
    if (quotesById.size() != quoteIds.size()) {
      throw new QuoteToOrderException('Quote does not exist');
    }
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
    List<Id> orderedQuoteIds = new List<Id>(eligibleQuoteIds);
    orderedQuoteIds.sort();
    List<Order> orders = new List<Order>();
    for (Id currentQuoteId : orderedQuoteIds) {
      Quote quoteRecord = quotesById.get(currentQuoteId);
      validate(quoteRecord, linesByQuoteId.get(currentQuoteId));
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
