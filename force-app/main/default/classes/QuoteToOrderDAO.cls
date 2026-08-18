/**
 * Combined data-access implementation for Quote conversion.
 *
 * Queries remain real SOQL, while all writes pass through IDMLExecutor. This
 * creates a useful second test seam: DAO mapping and DML orchestration can be
 * verified without committing records, and the generic Database wrapper is
 * tested once as shared infrastructure.
 */
public inherited sharing class QuoteToOrderDAO implements IQuoteToOrderDAO {
  private final IDMLExecutor dml;

  public QuoteToOrderDAO() {

    // Convenience constructor used by production composition.
    this(new DMLExecutor());
  }

  public QuoteToOrderDAO(IDMLExecutor dml) {

    this.dml = dml;
  }

  public Map<Id, Quote> findQuotes(Set<Id> quoteIds) {

    return new Map<Id, Quote>(
      [
        SELECT Id, Status, Converted_Order__c, AccountId, Pricebook2Id
        FROM Quote
        WHERE Id IN :quoteIds
      ]
    );
  }

  public List<QuoteLineItem> findQuoteLines(Set<Id> quoteIds) {

    return [
      SELECT QuoteId, PricebookEntryId, Quantity, UnitPrice
      FROM QuoteLineItem
      WHERE QuoteId IN :quoteIds
      ORDER BY QuoteId, Id
    ];
  }

  public Map<Id, Id> saveOrders(
    Map<Id, Order> ordersByQuoteId,
    Map<Id, List<OrderItem>> itemsByQuoteId
  ) {

    // Sort keys so SaveResult positions map deterministically back to Quote IDs.
    List<Id> quoteIds = new List<Id>(ordersByQuoteId.keySet());
    quoteIds.sort();
    List<Order> orders = new List<Order>();
    for (Id quoteId : quoteIds) {

      orders.add(ordersByQuoteId.get(quoteId));
    }
    List<SObject> orderRecords = new List<SObject>();
    orderRecords.addAll(orders);
    // The injected executor can be mocked; tests provide successful SaveResults
    // without performing Order or OrderItem DML.
    Database.SaveResult[] orderResults = dml.insertRecords(orderRecords, true);
    Map<Id, Id> orderIdsByQuoteId = new Map<Id, Id>();
    List<OrderItem> allItems = new List<OrderItem>();
    for (Integer index = 0; index < quoteIds.size(); index++) {

      Id quoteId = quoteIds[index];
      Id orderId = orderResults[index].getId();
      orderIdsByQuoteId.put(quoteId, orderId);
      for (OrderItem item : itemsByQuoteId.get(quoteId)) {

        item.OrderId = orderId;
        allItems.add(item);
      }
    }
    List<SObject> itemRecords = new List<SObject>();
    itemRecords.addAll(allItems);
    dml.insertRecords(itemRecords, true);
    return orderIdsByQuoteId;
  }

  public void markQuotesConverted(Map<Id, Id> orderIdsByQuoteId) {

    List<Quote> updates = new List<Quote>();
    List<Id> quoteIds = new List<Id>(orderIdsByQuoteId.keySet());
    quoteIds.sort();
    for (Id quoteId : quoteIds) {

      updates.add(
        new Quote(
          Id = quoteId,
          Converted_Order__c = orderIdsByQuoteId.get(quoteId)
        )
      );
    }
    List<SObject> quoteRecords = new List<SObject>();
    quoteRecords.addAll(updates);
    dml.updateRecords(quoteRecords, true);
  }
}
