public inherited sharing class LegacyQuoteToOrderService {
    public static Id convert(Id quoteId) {
        Quote quoteRecord = LegacyQuoteToOrderDataAccess.findQuote(quoteId);
        if (quoteRecord == null) {
            throw new QuoteToOrderException('Quote does not exist');
        }
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

        List<QuoteLineItem> quoteLines = LegacyQuoteToOrderDataAccess.findQuoteLines(quoteId);
        if (quoteLines.isEmpty()) {
            throw new QuoteToOrderException('Quote must contain at least one line');
        }

        Order orderRecord = new Order(
            AccountId = quoteRecord.AccountId,
            EffectiveDate = Date.today(),
            Pricebook2Id = quoteRecord.Pricebook2Id,
            Status = 'Draft'
        );
        LegacyQuoteToOrderDataAccess.insertOrder(orderRecord);

        List<OrderItem> orderItems = new List<OrderItem>();
        for (QuoteLineItem quoteLine : quoteLines) {
            orderItems.add(new OrderItem(
                OrderId = orderRecord.Id,
                PricebookEntryId = quoteLine.PricebookEntryId,
                Quantity = quoteLine.Quantity,
                UnitPrice = quoteLine.UnitPrice
            ));
        }
        LegacyQuoteToOrderDataAccess.insertOrderItems(orderItems);

        LegacyQuoteToOrderDataAccess.markQuoteConverted(quoteRecord.Id, orderRecord.Id);
        return orderRecord.Id;
    }
}
