public inherited sharing class SalesforceQuoteLineRepository implements IQuoteLineRepository {
    public List<QuoteLineItem> findByQuoteId(Id quoteId) {
        return [
            SELECT Id, PricebookEntryId, Quantity, UnitPrice
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
            ORDER BY Id
        ];
    }
}
