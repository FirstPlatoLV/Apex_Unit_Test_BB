public inherited sharing class LegacyQuoteToOrderService {
    public static Id convert(Id quoteId) {
        List<Quote> quotes = [
            SELECT Id, Status, Converted_Order__c, AccountId, Pricebook2Id
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        if (quotes.isEmpty()) {
            throw new QuoteToOrderException('Quote does not exist');
        }

        Quote quoteRecord = quotes[0];
        if (quoteRecord.Status != BrownbagDemoPolicy.acceptedQuoteStatus()) {
            throw new QuoteToOrderException('Quote status is not accepted');
        }
        if (quoteRecord.Converted_Order__c != null) {
            throw new QuoteToOrderException('Quote was already converted');
        }
        if (quoteRecord.AccountId == null) {
            throw new QuoteToOrderException('Quote Account is required');
        }
        if (quoteRecord.Pricebook2Id == null) {
            throw new QuoteToOrderException('Quote Price Book is required');
        }

        List<QuoteLineItem> quoteLines = [
            SELECT PricebookEntryId, Quantity, UnitPrice
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
            ORDER BY Id
        ];
        if (quoteLines.isEmpty()) {
            throw new QuoteToOrderException('Quote must contain at least one line');
        }

        Order orderRecord = new Order(
            AccountId = quoteRecord.AccountId,
            EffectiveDate = Date.today(),
            Pricebook2Id = quoteRecord.Pricebook2Id,
            Status = 'Draft'
        );
        insert orderRecord;

        List<OrderItem> orderItems = new List<OrderItem>();
        for (QuoteLineItem quoteLine : quoteLines) {
            orderItems.add(new OrderItem(
                OrderId = orderRecord.Id,
                PricebookEntryId = quoteLine.PricebookEntryId,
                Quantity = quoteLine.Quantity,
                UnitPrice = quoteLine.UnitPrice
            ));
        }
        insert orderItems;

        update new Quote(Id = quoteRecord.Id, Converted_Order__c = orderRecord.Id);
        return orderRecord.Id;
    }
}
