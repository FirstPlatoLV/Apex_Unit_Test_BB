public inherited sharing class LegacyQuoteToOrderDAO {
  public static Map<Id, Quote> findQuotes(Set<Id> quoteIds) {
    return new Map<Id, Quote>(
      [
        SELECT Id, Status, Converted_Order__c, AccountId, Pricebook2Id
        FROM Quote
        WHERE Id IN :quoteIds
      ]
    );
  }

  public static List<QuoteLineItem> findQuoteLines(Set<Id> quoteIds) {
    return [
      SELECT QuoteId, PricebookEntryId, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE QuoteId IN :quoteIds
      ORDER BY QuoteId, Id
    ];
  }

  public static void insertOrders(List<Order> orderRecords) {
    insert orderRecords;
  }

  public static void insertOrderItems(List<OrderItem> orderItems) {
    insert orderItems;
  }

  public static void markQuotesConverted(Map<Id, Id> orderIdsByQuoteId) {
    List<Quote> updates = new List<Quote>();
    for (Id quoteId : orderIdsByQuoteId.keySet()) {
      updates.add(
        new Quote(
          Id = quoteId,
          Converted_Order__c = orderIdsByQuoteId.get(quoteId)
        )
      );
    }
    update updates;
  }
}
