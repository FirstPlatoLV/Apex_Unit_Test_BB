trigger QuoteTrigger on Quote(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  Quote_Conversion_Policy__mdt conversionPolicy = QuoteTriggerDependencies.getPolicy();
  IQuoteToOrderService service;

  if (conversionPolicy?.Use_Legacy_Implementation__c == true) {
    service = QuoteTriggerDependencies.getLegacyService();
  } else {
    service = QuoteTriggerDependencies.getNewService();
  }

  new QuoteTriggerHandler(service)
    .handle(Trigger.operationType, Trigger.new, Trigger.oldMap);
}
