@IsTest
private class SalesforceRepositoriesTest {
    @IsTest
    static void quoteRepositoryFindsAndMarksQuote() {
        BrownbagTestDataFactory.Graph graph = BrownbagTestDataFactory.createAcceptedQuote(1);
        Order orderRecord = new Order(
            AccountId = graph.account.Id, EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(), Status = 'Draft'
        );
        insert orderRecord;
        SalesforceQuoteRepository repository = new SalesforceQuoteRepository();
        Quote found = repository.findById(graph.quoteRecord.Id);
        System.assertEquals(graph.account.Id, found.AccountId);
        System.assertEquals(Test.getStandardPricebookId(), found.Pricebook2Id);
        repository.markConverted(found.Id, orderRecord.Id);
        System.assertEquals(orderRecord.Id, [SELECT Converted_Order__c FROM Quote WHERE Id = :found.Id].Converted_Order__c);
        System.assertEquals(null, repository.findById('0Q0000000000001AAA'));
    }

    @IsTest
    static void quoteLineRepositoryReturnsQuoteLines() {
        BrownbagTestDataFactory.Graph graph = BrownbagTestDataFactory.createAcceptedQuote(2);
        List<QuoteLineItem> lines = new SalesforceQuoteLineRepository().findByQuoteId(graph.quoteRecord.Id);
        System.assertEquals(2, lines.size());
        System.assertEquals(graph.entries[0].Id, lines[0].PricebookEntryId);
    }

    @IsTest
    static void orderRepositoryInsertsOrderBeforeItems() {
        BrownbagTestDataFactory.Graph graph = BrownbagTestDataFactory.createAcceptedQuote(2);
        Order orderRecord = new Order(
            AccountId = graph.account.Id, EffectiveDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId(), Status = 'Draft'
        );
        List<OrderItem> items = new List<OrderItem>{
            new OrderItem(PricebookEntryId = graph.entries[0].Id, Quantity = 1, UnitPrice = 9),
            new OrderItem(PricebookEntryId = graph.entries[1].Id, Quantity = 2, UnitPrice = 10)
        };
        Id orderId = new SalesforceOrderRepository().save(orderRecord, items);
        System.assertNotEquals(null, orderId);
        System.assertEquals(2, [SELECT COUNT() FROM OrderItem WHERE OrderId = :orderId]);
        System.assertEquals(orderId, items[0].OrderId);
    }
}
