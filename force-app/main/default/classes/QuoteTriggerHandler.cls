public inherited sharing class QuoteTriggerHandler {
  private final IQuoteConversionPolicy policy;
  private final IQuoteToOrderService legacyService;
  private final IQuoteToOrderService newService;

  public QuoteTriggerHandler(
    IQuoteConversionPolicy policy,
    IQuoteToOrderService legacyService,
    IQuoteToOrderService newService
  ) {
    this.policy = policy;
    this.legacyService = legacyService;
    this.newService = newService;
  }

  public void handle(
    System.TriggerOperation operation,
    List<Quote> newQuotes,
    Map<Id, Quote> oldQuotesById
  ) {
    if (operation == System.TriggerOperation.AFTER_UPDATE) {
      afterUpdate(newQuotes, oldQuotesById);
    }
  }

  private void afterUpdate(
    List<Quote> newQuotes,
    Map<Id, Quote> oldQuotesById
  ) {
    Set<Id> changedQuoteIds = new Set<Id>();
    for (Quote quoteRecord : newQuotes) {
      Quote oldQuote = oldQuotesById.get(quoteRecord.Id);
      if (
        quoteRecord.Status != oldQuote.Status &&
        quoteRecord.Converted_Order__c == null
      ) {
        changedQuoteIds.add(quoteRecord.Id);
      }
    }

    if (!changedQuoteIds.isEmpty()) {
      Quote_Conversion_Policy__mdt conversionPolicy = policy.getPolicy();
      IQuoteToOrderService service = conversionPolicy
          ?.Use_Legacy_Implementation__c == true
        ? legacyService
        : newService;
      service.convertQuotes(changedQuoteIds);
    }
  }
}
