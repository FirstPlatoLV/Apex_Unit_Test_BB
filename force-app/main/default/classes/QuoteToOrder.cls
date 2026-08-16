public inherited sharing class QuoteToOrder {
  public static Id convert(Id quoteId) {
    QuoteToOrderResult result = QuoteToOrderServiceFactory.createDefault()
      .convert(quoteId);
    return result?.orderId;
  }

  public static Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds) {
    return QuoteToOrderServiceFactory.createDefault().convert(quoteIds);
  }
}
