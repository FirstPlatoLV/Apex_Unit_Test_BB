public inherited sharing class QuoteToOrderServiceFactory {
  public static QuoteToOrderService createDefault() {
    return new QuoteToOrderService(
      new QuoteToOrderDAO(),
      new SystemDateProvider(),
      BrownbagDemoPolicy.acceptedQuoteStatus()
    );
  }
}
