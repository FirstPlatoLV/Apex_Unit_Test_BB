@IsTest
private class QuoteToOrderDAOTest {
    @IsTest static void queriesSavesAndMarksInBulk(){
        BrownbagTestDataFactory.Graph first=BrownbagTestDataFactory.createAcceptedQuote(2), second=BrownbagTestDataFactory.createAcceptedQuote(1);
        Set<Id> quoteIds=new Set<Id>{first.quoteRecord.Id,second.quoteRecord.Id}; QuoteToOrderDAO dao=new QuoteToOrderDAO();
        System.assertEquals(2,dao.findQuotes(quoteIds).size()); System.assertEquals(3,dao.findQuoteLines(quoteIds).size());
        Map<Id,Order> orders=new Map<Id,Order>(); Map<Id,List<OrderItem>> items=new Map<Id,List<OrderItem>>();
        for(Id quoteId:quoteIds){ orders.put(quoteId,new Order(AccountId=quoteId==first.quoteRecord.Id?first.account.Id:second.account.Id,EffectiveDate=Date.today(),Pricebook2Id=Test.getStandardPricebookId(),Status='Draft')); }
        items.put(first.quoteRecord.Id,new List<OrderItem>{new OrderItem(PricebookEntryId=first.entries[0].Id,Quantity=1,UnitPrice=9)});
        items.put(second.quoteRecord.Id,new List<OrderItem>{new OrderItem(PricebookEntryId=second.entries[0].Id,Quantity=1,UnitPrice=9)});
        Map<Id,Id> orderIds=dao.saveOrders(orders,items); dao.markQuotesConverted(orderIds);
        Set<Id> savedOrderIds=new Set<Id>(orderIds.values());
        System.assertEquals(2,[SELECT COUNT() FROM Order WHERE Id IN :savedOrderIds]);
        System.assertEquals(2,[SELECT COUNT() FROM OrderItem WHERE OrderId IN :savedOrderIds]);
        Order savedFirst=[SELECT AccountId,EffectiveDate,Pricebook2Id,Status FROM Order WHERE Id=:orderIds.get(first.quoteRecord.Id)];
        OrderItem savedItem=[SELECT PricebookEntryId,Quantity,UnitPrice FROM OrderItem WHERE OrderId=:savedFirst.Id LIMIT 1];
        System.assertEquals(first.account.Id,savedFirst.AccountId); System.assertEquals(Date.today(),savedFirst.EffectiveDate);
        System.assertEquals(Test.getStandardPricebookId(),savedFirst.Pricebook2Id); System.assertEquals('Draft',savedFirst.Status);
        System.assertEquals(first.entries[0].Id,savedItem.PricebookEntryId); System.assertEquals(Decimal.valueOf(1),savedItem.Quantity); System.assertEquals(Decimal.valueOf(9),savedItem.UnitPrice);
        for(Quote q:[SELECT Id,Converted_Order__c FROM Quote WHERE Id IN :quoteIds])System.assertEquals(orderIds.get(q.Id),q.Converted_Order__c);
    }
}
