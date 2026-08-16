public inherited sharing class QuoteToOrderServiceFactory {
    public static QuoteToOrderService createDefault() {
        return new QuoteToOrderService(
            new SalesforceQuoteRepository(),
            new SalesforceQuoteLineRepository(),
            new SalesforceOrderRepository(),
            new SystemDateProvider(),
            BrownbagDemoPolicy.acceptedQuoteStatus()
        );
    }
}
