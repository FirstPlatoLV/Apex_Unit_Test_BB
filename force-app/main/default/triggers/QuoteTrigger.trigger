trigger QuoteTrigger on Quote(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {

  // The feature flag lives at the outermost composition boundary. Both branches
  // produce the same interface, leaving the handler independent of the choice.
  Quote_Conversion_Policy__mdt conversionPolicy = QuoteTriggerDependencies.getPolicy();
  IQuoteToOrderService service;

  if (conversionPolicy?.Use_Legacy_Implementation__c == true) {

    // Transitional path: static legacy internals exposed through the interface.
    service = QuoteTriggerDependencies.getLegacyService();
  } else {

    // Fully isolated path: constructor-injected service and DAO dependencies.
    service = QuoteTriggerDependencies.getNewService();
  }

  // Keep the trigger thin: context filtering and delegation belong to a class.
  new QuoteTriggerHandler(service)
    .handle(Trigger.operationType, Trigger.new, Trigger.oldMap);
}
