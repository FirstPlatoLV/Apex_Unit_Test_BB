public inherited sharing class QuoteToOrder {
    public static Id convert(Id quoteId) {
        return QuoteToOrderServiceFactory.createDefault().convert(quoteId).orderId;
    }
}
