public inherited sharing class LegacyQuoteToOrderDataAccess {
    public static Quote findQuote(Id quoteId) {
        List<Quote> quotes = [
            SELECT Id, Status, Converted_Order__c, AccountId, Pricebook2Id
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        return quotes.isEmpty() ? null : quotes[0];
    }

    public static List<QuoteLineItem> findQuoteLines(Id quoteId) {
        return [
            SELECT PricebookEntryId, Quantity, UnitPrice
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
            ORDER BY Id
        ];
    }

    public static void insertOrder(Order orderRecord) {
        insert orderRecord;
    }

    public static void insertOrderItems(List<OrderItem> orderItems) {
        insert orderItems;
    }

    public static void markQuoteConverted(Id quoteId, Id orderId) {
        update new Quote(Id = quoteId, Converted_Order__c = orderId);
    }
}
