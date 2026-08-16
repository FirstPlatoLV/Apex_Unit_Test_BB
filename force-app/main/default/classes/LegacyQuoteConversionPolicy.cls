public inherited sharing class LegacyQuoteConversionPolicy {
  public static String acceptedQuoteStatus() {
    return Quote_Conversion_Policy__mdt.getInstance('Default')
      ?.Accepted_Quote_Status__c;
  }
}
