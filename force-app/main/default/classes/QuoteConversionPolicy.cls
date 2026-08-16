public inherited sharing class QuoteConversionPolicy implements IQuoteConversionPolicy {
  public String acceptedQuoteStatus() {
    return Quote_Conversion_Policy__mdt.getInstance('Default')
      ?.Accepted_Quote_Status__c;
  }
}
