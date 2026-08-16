@IsTest
private class LegacyQuoteToOrderServiceTest {
    @IsTest
    static void acceptedQuoteCreatesOrderAndLines() {
        Account accountRecord = new Account(Name = 'Brown-bag Account');
        insert accountRecord;

        Opportunity opportunity = new Opportunity(
            Name = 'Brown-bag Opportunity',
            AccountId = accountRecord.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opportunity;

        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Brown-bag Product A', IsActive = true),
            new Product2(Name = 'Brown-bag Product B', IsActive = true)
        };
        insert products;

        List<PricebookEntry> entries = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = products[0].Id, UnitPrice = 10, IsActive = true),
            new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = products[1].Id, UnitPrice = 25, IsActive = true)
        };
        insert entries;

        Quote quoteRecord = new Quote(
            Name = 'Brown-bag Quote',
            OpportunityId = opportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Accepted'
        );
        insert quoteRecord;
        insert new List<QuoteLineItem>{
            new QuoteLineItem(QuoteId = quoteRecord.Id, PricebookEntryId = entries[0].Id, Quantity = 2, UnitPrice = 9),
            new QuoteLineItem(QuoteId = quoteRecord.Id, PricebookEntryId = entries[1].Id, Quantity = 3, UnitPrice = 24)
        };

        Test.startTest();
        Id orderId = LegacyQuoteToOrderService.convert(quoteRecord.Id);
        Test.stopTest();

        Order savedOrder = [SELECT AccountId, EffectiveDate, Pricebook2Id, Status FROM Order WHERE Id = :orderId];
        List<OrderItem> savedItems = [SELECT PricebookEntryId, Quantity, UnitPrice FROM OrderItem WHERE OrderId = :orderId ORDER BY UnitPrice];
        Quote savedQuote = [SELECT Converted_Order__c FROM Quote WHERE Id = :quoteRecord.Id];
        System.assertEquals(accountRecord.Id, savedOrder.AccountId);
        System.assertEquals(Date.today(), savedOrder.EffectiveDate);
        System.assertEquals(Test.getStandardPricebookId(), savedOrder.Pricebook2Id);
        System.assertEquals('Draft', savedOrder.Status);
        System.assertEquals(2, savedItems.size());
        System.assertEquals(entries[0].Id, savedItems[0].PricebookEntryId);
        System.assertEquals(Decimal.valueOf(2), savedItems[0].Quantity);
        System.assertEquals(Decimal.valueOf(9), savedItems[0].UnitPrice);
        System.assertEquals(entries[1].Id, savedItems[1].PricebookEntryId);
        System.assertEquals(Decimal.valueOf(3), savedItems[1].Quantity);
        System.assertEquals(Decimal.valueOf(24), savedItems[1].UnitPrice);
        System.assertEquals(orderId, savedQuote.Converted_Order__c);
    }

    @IsTest
    static void nonAcceptedQuoteIsRejected() {
        Account accountRecord = new Account(Name = 'Rejected Account');
        insert accountRecord;
        Opportunity opportunity = new Opportunity(
            Name = 'Rejected Opportunity', AccountId = accountRecord.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(30)
        );
        insert opportunity;
        Quote quoteRecord = new Quote(Name = 'Draft Quote', OpportunityId = opportunity.Id, Status = 'Draft');
        insert quoteRecord;

        try {
            LegacyQuoteToOrderService.convert(quoteRecord.Id);
            System.assert(false, 'Expected rejection');
        } catch (QuoteToOrderException error) {
            System.assertEquals('Quote status is not accepted', error.getMessage());
        }
        System.assertEquals(0, [SELECT COUNT() FROM Order WHERE AccountId = :accountRecord.Id]);
    }
}
