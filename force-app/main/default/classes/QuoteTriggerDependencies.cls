public inherited sharing class QuoteTriggerDependencies {
  @TestVisible
  private static IQuoteConversionPolicy policyOverride;
  @TestVisible
  private static IQuoteToOrderService legacyServiceOverride;
  @TestVisible
  private static IQuoteToOrderService newServiceOverride;

  public static Quote_Conversion_Policy__mdt getPolicy() {
    IQuoteConversionPolicy policy = policyOverride == null
      ? new QuoteConversionPolicy()
      : policyOverride;
    return policy.getPolicy();
  }

  public static IQuoteToOrderService getLegacyService() {
    return legacyServiceOverride == null
      ? new LegacyQuoteToOrderService()
      : legacyServiceOverride;
  }

  public static IQuoteToOrderService getNewService() {
    return newServiceOverride == null
      ? QuoteToOrderServiceFactory.createDefault()
      : newServiceOverride;
  }
}
