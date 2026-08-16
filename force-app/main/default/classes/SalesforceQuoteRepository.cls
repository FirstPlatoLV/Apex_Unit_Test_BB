public inherited sharing class SalesforceQuoteRepository implements IQuoteRepository {
    public Quote findById(Id quoteId) {
        List<Quote> records = [
            SELECT Id, Status, Converted_Order__c, AccountId, Pricebook2Id
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    public void markConverted(Id quoteId, Id orderId) {
        update new Quote(Id = quoteId, Converted_Order__c = orderId);
    }
}
