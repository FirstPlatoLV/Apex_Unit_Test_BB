public inherited sharing class QuoteToOrderDAO implements IQuoteToOrderDAO {
    public Map<Id, Quote> findQuotes(Set<Id> quoteIds) {
        return new Map<Id, Quote>([
            SELECT Id, Status, Converted_Order__c, AccountId, Pricebook2Id
            FROM Quote WHERE Id IN :quoteIds
        ]);
    }

    public List<QuoteLineItem> findQuoteLines(Set<Id> quoteIds) {
        return [
            SELECT QuoteId, PricebookEntryId, Quantity, UnitPrice
            FROM QuoteLineItem WHERE QuoteId IN :quoteIds ORDER BY QuoteId, Id
        ];
    }

    public Map<Id, Id> saveOrders(Map<Id, Order> ordersByQuoteId, Map<Id, List<OrderItem>> itemsByQuoteId) {
        List<Id> quoteIds = new List<Id>(ordersByQuoteId.keySet());
        quoteIds.sort();
        List<Order> orders = new List<Order>();
        for (Id quoteId : quoteIds) orders.add(ordersByQuoteId.get(quoteId));
        insert orders;
        Map<Id, Id> orderIdsByQuoteId = new Map<Id, Id>();
        List<OrderItem> allItems = new List<OrderItem>();
        for (Integer index = 0; index < quoteIds.size(); index++) {
            Id quoteId = quoteIds[index];
            orderIdsByQuoteId.put(quoteId, orders[index].Id);
            for (OrderItem item : itemsByQuoteId.get(quoteId)) {
                item.OrderId = orders[index].Id;
                allItems.add(item);
            }
        }
        insert allItems;
        return orderIdsByQuoteId;
    }

    public void markQuotesConverted(Map<Id, Id> orderIdsByQuoteId) {
        List<Quote> updates = new List<Quote>();
        for (Id quoteId : orderIdsByQuoteId.keySet()) {
            updates.add(new Quote(Id = quoteId, Converted_Order__c = orderIdsByQuoteId.get(quoteId)));
        }
        update updates;
    }
}
