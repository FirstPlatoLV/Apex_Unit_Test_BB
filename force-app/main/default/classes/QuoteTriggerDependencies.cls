/**
 * Production composition root for Quote trigger dependencies.
 *
 * Object construction is kept out of QuoteTriggerHandler so the handler remains
 * independently testable. The metadata flag chooses which fully composed
 * IQuoteToOrderService is passed to it.
 */
public inherited sharing class QuoteTriggerDependencies {
  public static Quote_Conversion_Policy__mdt getPolicy() {
    return new QuoteConversionPolicy().getPolicy();
  }

  public static IQuoteToOrderService getLegacyService() {
    // The transitional legacy class now satisfies the interface while retaining
    // its original static API and hardwired internals.
    return new LegacyQuoteToOrderService();
  }

  public static IQuoteToOrderService getNewService() {
    // This is the only place the refactored production dependency graph is wired.
    return new QuoteToOrderService(
      new QuoteToOrderDAO(),
      new SystemDateProvider(),
      new QuoteConversionPolicy()
    );
  }
}
