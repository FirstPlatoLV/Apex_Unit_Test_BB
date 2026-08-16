public inherited sharing class QuoteTriggerHandler {
  private final IQuoteToOrderService service;

  public QuoteTriggerHandler(IQuoteToOrderService service) {
    this.service = service;
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
      service.convert(changedQuoteIds);
    }
  }
}
