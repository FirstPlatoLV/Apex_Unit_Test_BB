/**
 * Static data-access helper used by the legacy service.
 *
 * It centralizes reusable queries and the Quote-update mapping, while the legacy
 * service performs straightforward Order and Order Item inserts directly. These
 * static methods still prevent the service from substituting this dependency
 * with a mock, so the behavior is covered through data-heavy integration tests.
 */
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
