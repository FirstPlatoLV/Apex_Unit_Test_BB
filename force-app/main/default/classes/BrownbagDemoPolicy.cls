public inherited sharing class BrownbagDemoPolicy {
    public static String acceptedQuoteStatus() {
        Brownbag_Demo_Config__mdt config = Brownbag_Demo_Config__mdt.getInstance('Default');
        if (config == null || String.isBlank(config.Accepted_Quote_Status__c)) {
            throw new QuoteToOrderException('Accepted Quote status is not configured');
        }
        return config.Accepted_Quote_Status__c;
    }
}
