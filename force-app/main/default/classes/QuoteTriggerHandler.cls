/**
 * Trigger-context coordinator with no knowledge of implementation selection.
 *
 * It filters trigger events and delegates eligible Quote IDs to the single
 * service chosen by the trigger. Injecting that service keeps context behavior
 * easy to test without invoking conversion logic or DML.
 */
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

      // All contexts are declared on the trigger for future extension, but Quote
      // conversion currently reacts only after a persisted status transition.
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
      // Converted Quotes are ignored to prevent repeat conversion when later
      // updates change their status again.
      if (
        quoteRecord.Status != oldQuote.Status &&
        quoteRecord.Converted_Order__c == null
      ) {

        changedQuoteIds.add(quoteRecord.Id);
      }
    }

    if (!changedQuoteIds.isEmpty()) {

      // Status eligibility belongs to the service/policy. The handler only
      // detects transitions, so both implementations receive the same input.
      try {

        service.convertQuotes(changedQuoteIds);
      } catch (Exception error) {

        // Convert a service failure into record-level trigger feedback. This
        // keeps the transaction atomic and identifies only the Quotes included
        // in the failed conversion attempt.
        for (Quote quoteRecord : newQuotes) {

          if (changedQuoteIds.contains(quoteRecord.Id)) {

            quoteRecord.addError(
              'Quote conversion failed: ' + error.getMessage()
            );
          }
        }
      }
    }
  }
}
