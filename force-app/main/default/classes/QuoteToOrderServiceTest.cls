@IsTest
private class QuoteToOrderServiceTest {
    private static final Id QUOTE_ID='0Q0000000000001AAA', ACCOUNT_ID='001000000000001AAA', PRICEBOOK_ID='01s000000000001AAA';
    private static final Id ENTRY_ONE_ID='01u000000000001AAA', ENTRY_TWO_ID='01u000000000002AAA', ORDER_ID='801000000000001AAA';
    private static final Date FIXED_DATE=Date.newInstance(2030,4,15);
    private class DAOFailureException extends Exception {}
    private class Fixture {
        Mock daoMock=Mock.forType(IQuoteToOrderDAO.class), dateMock=Mock.forType(IDateProvider.class);
        IQuoteToOrderDAO dao=(IQuoteToOrderDAO)daoMock.stub; IDateProvider dates=(IDateProvider)dateMock.stub;
        QuoteToOrderService service(){ return new QuoteToOrderService(dao,dates,'Accepted'); }
    }

    @IsTest static void acceptedQuoteMapsAndPersistsTwoLines() {
        Fixture f=configured(quoteWith('Accepted',null,ACCOUNT_ID,PRICEBOOK_ID),twoLines());
        f.dateMock.spyOn('today').returns(FIXED_DATE);
        Map<Id,Order> expectedOrders=new Map<Id,Order>{QUOTE_ID=>new Order(AccountId=ACCOUNT_ID,EffectiveDate=FIXED_DATE,Pricebook2Id=PRICEBOOK_ID,Status='Draft')};
        Map<Id,List<OrderItem>> expectedItems=new Map<Id,List<OrderItem>>{QUOTE_ID=>new List<OrderItem>{new OrderItem(PricebookEntryId=ENTRY_ONE_ID,Quantity=2,UnitPrice=9),new OrderItem(PricebookEntryId=ENTRY_TWO_ID,Quantity=3,UnitPrice=24)}};
        MethodSpy save=f.daoMock.spyOn('saveOrders');
        save.whenCalledWith(Argument.any(),Argument.any()).thenReturn(new Map<Id,Id>{QUOTE_ID=>ORDER_ID});
        MethodSpy mark=f.daoMock.spyOn('markQuotesConverted');
        QuoteToOrderResult result=f.service().convert(QUOTE_ID);
        System.assertEquals(ORDER_ID,result.orderId); System.assertEquals(2,result.orderItemCount);
        Expect.that(save).hasBeenCalledTimes(1);
        Expect.that(mark).hasBeenCalledWith(Argument.jsonEquals(new Map<Id,Id>{QUOTE_ID=>ORDER_ID}));
    }
    @IsTest static void nonAcceptedQuoteDoesNotSave(){ assertRejected(configured(quoteWith('Draft',null,ACCOUNT_ID,PRICEBOOK_ID),twoLines()),'Quote status is not accepted'); }
    @IsTest static void alreadyConvertedQuoteDoesNotSave(){ assertRejected(configured(quoteWith('Accepted',ORDER_ID,ACCOUNT_ID,PRICEBOOK_ID),twoLines()),'Quote was already converted'); }
    @IsTest static void quoteWithoutLinesDoesNotSave(){ assertRejected(configured(quoteWith('Accepted',null,ACCOUNT_ID,PRICEBOOK_ID),new List<QuoteLineItem>()),'Quote must contain at least one line'); }
    @IsTest static void missingQuoteDoesNotSave(){ assertRejected(configured(null,twoLines()),'Quote does not exist'); }
    @IsTest static void missingContextDoesNotSave(){ assertRejected(configured(quoteWith('Accepted',null,null,PRICEBOOK_ID),twoLines()),'Quote Account is required'); assertRejected(configured(quoteWith('Accepted',null,ACCOUNT_ID,null),twoLines()),'Quote Price Book is required'); }
    @IsTest static void persistenceFailurePropagatesAndDoesNotMark(){
        Fixture f=configured(quoteWith('Accepted',null,ACCOUNT_ID,PRICEBOOK_ID),twoLines()); f.dateMock.spyOn('today').returns(FIXED_DATE);
        MethodSpy save=f.daoMock.spyOn('saveOrders'); save.throwsException(new DAOFailureException('Order persistence failed')); MethodSpy mark=f.daoMock.spyOn('markQuotesConverted');
        try { f.service().convert(QUOTE_ID); System.assert(false,'Expected DAO failure'); } catch(DAOFailureException e){ System.assertEquals('Order persistence failed',e.getMessage()); }
        Expect.that(save).hasBeenCalledTimes(1); Expect.that(mark).hasBeenCalledTimes(0);
    }
    private static Fixture configured(Quote q,List<QuoteLineItem> lines){
        Fixture f=new Fixture(); Map<Id,Quote> quotes=new Map<Id,Quote>(); if(q!=null)quotes.put(QUOTE_ID,q);
        f.daoMock.spyOn('findQuotes').whenCalledWith(new Set<Id>{QUOTE_ID}).thenReturn(quotes);
        f.daoMock.spyOn('findQuoteLines').whenCalledWith(new Set<Id>{QUOTE_ID}).thenReturn(lines); return f;
    }
    private static void assertRejected(Fixture f,String message){ MethodSpy save=f.daoMock.spyOn('saveOrders'); try{f.service().convert(QUOTE_ID);System.assert(false,'Expected rejection');}catch(QuoteToOrderException e){System.assertEquals(message,e.getMessage());} Expect.that(save).hasBeenCalledTimes(0); }
    private static Quote quoteWith(String status,Id converted,Id accountId,Id pricebookId){ return (Quote)JSON.deserialize(JSON.serialize(new Map<String,Object>{'Id'=>QUOTE_ID,'Status'=>status,'Converted_Order__c'=>converted,'AccountId'=>accountId,'Pricebook2Id'=>pricebookId}),Quote.class); }
    private static List<QuoteLineItem> twoLines(){
        List<Object> raw=new List<Object>{new Map<String,Object>{'QuoteId'=>QUOTE_ID,'PricebookEntryId'=>ENTRY_ONE_ID,'Quantity'=>2,'UnitPrice'=>9},new Map<String,Object>{'QuoteId'=>QUOTE_ID,'PricebookEntryId'=>ENTRY_TWO_ID,'Quantity'=>3,'UnitPrice'=>24}};
        return (List<QuoteLineItem>)JSON.deserialize(JSON.serialize(raw),List<QuoteLineItem>.class);
    }
}
