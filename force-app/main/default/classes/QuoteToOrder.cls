public inherited sharing class QuoteToOrder {
  public static Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds) {
    return QuoteToOrderServiceFactory.createDefault().convert(quoteIds);
  }
}
