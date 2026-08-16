@IsTest
private class QuoteToOrderServiceTest {
    private static final Id QUOTE_ID = '0Q0000000000001AAA';
    private static final Id ACCOUNT_ID = '001000000000001AAA';
    private static final Id PRICEBOOK_ID = '01s000000000001AAA';
    private static final Id ENTRY_ONE_ID = '01u000000000001AAA';
    private static final Id ENTRY_TWO_ID = '01u000000000002AAA';
    private static final Id ORDER_ID = '801000000000001AAA';
    private static final Date FIXED_DATE = Date.newInstance(2030, 4, 15);

    private class RepositoryFailureException extends Exception {
    }

    private class Fixture {
        Mock quoteMock = Mock.forType(IQuoteRepository.class);
        Mock lineMock = Mock.forType(IQuoteLineRepository.class);
        Mock orderMock = Mock.forType(IOrderRepository.class);
        Mock dateMock = Mock.forType(IDateProvider.class);
        IQuoteRepository quotes = (IQuoteRepository) quoteMock.stub;
        IQuoteLineRepository lines = (IQuoteLineRepository) lineMock.stub;
        IOrderRepository orders = (IOrderRepository) orderMock.stub;
        IDateProvider dates = (IDateProvider) dateMock.stub;

        QuoteToOrderService service() {
            return new QuoteToOrderService(quotes, lines, orders, dates, 'Accepted');
        }
    }

    @IsTest
    static void acceptedQuoteMapsAndPersistsTwoLines() {
        Fixture fixture = new Fixture();
        Quote quoteRecord = quoteWith('Accepted', null, ACCOUNT_ID, PRICEBOOK_ID);
        List<QuoteLineItem> quoteLines = twoLines();
        Order expectedOrder = new Order(
            AccountId = ACCOUNT_ID, EffectiveDate = FIXED_DATE,
            Pricebook2Id = PRICEBOOK_ID, Status = 'Draft'
        );
        List<OrderItem> expectedItems = new List<OrderItem>{
            new OrderItem(PricebookEntryId = ENTRY_ONE_ID, Quantity = 2, UnitPrice = 9),
            new OrderItem(PricebookEntryId = ENTRY_TWO_ID, Quantity = 3, UnitPrice = 24)
        };

        fixture.quoteMock.spyOn('findById').whenCalledWith(QUOTE_ID).thenReturn(quoteRecord);
        fixture.lineMock.spyOn('findByQuoteId').whenCalledWith(QUOTE_ID).thenReturn(quoteLines);
        fixture.dateMock.spyOn('today').returns(FIXED_DATE);
        MethodSpy saveSpy = fixture.orderMock.spyOn('save');
        saveSpy.whenCalledWith(Argument.jsonEquals(expectedOrder), Argument.jsonEquals(expectedItems)).thenReturn(ORDER_ID);
        MethodSpy markSpy = fixture.quoteMock.spyOn('markConverted');

        QuoteToOrderResult result = fixture.service().convert(QUOTE_ID);

        System.assertEquals(ORDER_ID, result.orderId);
        System.assertEquals(2, result.orderItemCount);
        Expect.that(saveSpy).hasBeenCalledTimes(1);
        Expect.that(saveSpy).hasBeenCalledWith(Argument.jsonEquals(expectedOrder), Argument.jsonEquals(expectedItems));
        Expect.that(markSpy).hasBeenCalledWith(QUOTE_ID, ORDER_ID);
    }

    @IsTest
    static void nonAcceptedQuoteDoesNotSave() {
        Fixture fixture = configuredFixture(quoteWith('Draft', null, ACCOUNT_ID, PRICEBOOK_ID), twoLines());
        assertRejected(fixture, 'Quote status is not accepted');
    }

    @IsTest
    static void alreadyConvertedQuoteDoesNotSave() {
        Fixture fixture = configuredFixture(quoteWith('Accepted', ORDER_ID, ACCOUNT_ID, PRICEBOOK_ID), twoLines());
        assertRejected(fixture, 'Quote was already converted');
    }

    @IsTest
    static void quoteWithoutLinesDoesNotSave() {
        Fixture fixture = configuredFixture(quoteWith('Accepted', null, ACCOUNT_ID, PRICEBOOK_ID), new List<QuoteLineItem>());
        assertRejected(fixture, 'Quote must contain at least one line');
    }

    @IsTest
    static void missingQuoteDoesNotSave() {
        Fixture fixture = configuredFixture(null, twoLines());
        assertRejected(fixture, 'Quote does not exist');
    }

    @IsTest
    static void missingContextDoesNotSave() {
        Fixture noAccount = configuredFixture(quoteWith('Accepted', null, null, PRICEBOOK_ID), twoLines());
        assertRejected(noAccount, 'Quote Account is required');
        Fixture noPricebook = configuredFixture(quoteWith('Accepted', null, ACCOUNT_ID, null), twoLines());
        assertRejected(noPricebook, 'Quote Price Book is required');
    }

    @IsTest
    static void persistenceFailurePropagatesAndDoesNotMark() {
        Fixture fixture = configuredFixture(quoteWith('Accepted', null, ACCOUNT_ID, PRICEBOOK_ID), twoLines());
        fixture.dateMock.spyOn('today').returns(FIXED_DATE);
        MethodSpy saveSpy = fixture.orderMock.spyOn('save');
        saveSpy.throwsException(new RepositoryFailureException('Order persistence failed'));
        MethodSpy markSpy = fixture.quoteMock.spyOn('markConverted');

        try {
            fixture.service().convert(QUOTE_ID);
            System.assert(false, 'Expected repository failure');
        } catch (RepositoryFailureException error) {
            System.assertEquals('Order persistence failed', error.getMessage());
        }
        Expect.that(saveSpy).hasBeenCalledTimes(1);
        Expect.that(markSpy).hasBeenCalledTimes(0);
    }

    private static Fixture configuredFixture(Quote quoteRecord, List<QuoteLineItem> quoteLines) {
        Fixture fixture = new Fixture();
        fixture.quoteMock.spyOn('findById').whenCalledWith(QUOTE_ID).thenReturn(quoteRecord);
        fixture.lineMock.spyOn('findByQuoteId').whenCalledWith(QUOTE_ID).thenReturn(quoteLines);
        return fixture;
    }

    private static void assertRejected(Fixture fixture, String expectedMessage) {
        MethodSpy saveSpy = fixture.orderMock.spyOn('save');
        try {
            fixture.service().convert(QUOTE_ID);
            System.assert(false, 'Expected rejection');
        } catch (QuoteToOrderException error) {
            System.assertEquals(expectedMessage, error.getMessage());
        }
        Expect.that(saveSpy).hasBeenCalledTimes(0);
    }

    private static Quote quoteWith(String status, Id convertedOrderId, Id accountId, Id pricebookId) {
        Map<String, Object> values = new Map<String, Object>{
            'Id' => QUOTE_ID, 'Status' => status,
            'Converted_Order__c' => convertedOrderId,
            'AccountId' => accountId, 'Pricebook2Id' => pricebookId
        };
        return (Quote) JSON.deserialize(JSON.serialize(values), Quote.class);
    }

    private static List<QuoteLineItem> twoLines() {
        return new List<QuoteLineItem>{
            new QuoteLineItem(PricebookEntryId = ENTRY_ONE_ID, Quantity = 2, UnitPrice = 9),
            new QuoteLineItem(PricebookEntryId = ENTRY_TWO_ID, Quantity = 3, UnitPrice = 24)
        };
    }
}
