public inherited sharing class BrownbagDemoPolicy implements IQuoteToOrderPolicy {
  public String acceptedQuoteStatus() {
    return Brownbag_Demo_Config__mdt.getInstance('Default')
      ?.Accepted_Quote_Status__c;
  }
}
