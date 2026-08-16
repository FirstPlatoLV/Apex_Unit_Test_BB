@IsTest
private class QuoteToOrderFacadeTest {
    @IsTest
    static void convertTest() {
        BrownbagTestDataFactory.Graph graph = BrownbagTestDataFactory.createAcceptedQuote(2);
        Id orderId = QuoteToOrder.convert(graph.quoteRecord.Id);
        Order saved = [SELECT AccountId, Pricebook2Id, Status FROM Order WHERE Id = :orderId];
        System.assertEquals(graph.account.Id, saved.AccountId);
        System.assertEquals(Test.getStandardPricebookId(), saved.Pricebook2Id);
        System.assertEquals('Draft', saved.Status);
        System.assertEquals(2, [SELECT COUNT() FROM OrderItem WHERE OrderId = :orderId]);
        System.assertEquals(orderId, [SELECT Converted_Order__c FROM Quote WHERE Id = :graph.quoteRecord.Id].Converted_Order__c);
    }
}
