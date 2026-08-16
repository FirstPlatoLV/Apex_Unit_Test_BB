public inherited sharing class QuoteTriggerDependencies {
  public static Quote_Conversion_Policy__mdt getPolicy() {
    return new QuoteConversionPolicy().getPolicy();
  }

  public static IQuoteToOrderService getLegacyService() {
    return new LegacyQuoteToOrderService();
  }

  public static IQuoteToOrderService getNewService() {
    return new QuoteToOrderService(
      new QuoteToOrderDAO(),
      new SystemDateProvider(),
      new QuoteConversionPolicy()
    );
  }
}
