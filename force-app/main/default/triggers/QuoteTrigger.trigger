trigger QuoteTrigger on Quote(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  if (Trigger.isAfter && Trigger.isUpdate) {
    String acceptedStatus = LegacyQuoteConversionPolicy.acceptedQuoteStatus();
    Set<Id> eligibleQuoteIds = new Set<Id>();

    for (Quote quoteRecord : Trigger.new) {
      Quote oldQuote = Trigger.oldMap.get(quoteRecord.Id);
      if (
        quoteRecord.Status == acceptedStatus &&
        oldQuote.Status != acceptedStatus &&
        quoteRecord.Converted_Order__c == null
      ) {
        eligibleQuoteIds.add(quoteRecord.Id);
      }
    }

    if (!eligibleQuoteIds.isEmpty()) {
      QuoteToOrder.convert(eligibleQuoteIds);
    }
  }
}
