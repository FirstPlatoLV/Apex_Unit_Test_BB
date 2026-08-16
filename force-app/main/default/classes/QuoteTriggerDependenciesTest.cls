@IsTest
private class QuoteTriggerDependenciesTest {
  @IsTest
  static void getPolicyTest() {
    Mock policyMock = Mock.forType(IQuoteConversionPolicy.class);
    Quote_Conversion_Policy__mdt expectedPolicy = new Quote_Conversion_Policy__mdt(
      Use_Legacy_Implementation__c = true
    );
    policyMock.spyOn('getPolicy').returns(expectedPolicy);
    QuoteTriggerDependencies.policyOverride = (IQuoteConversionPolicy) policyMock.stub;

    Quote_Conversion_Policy__mdt actualPolicy = QuoteTriggerDependencies.getPolicy();

    Assert.areEqual(expectedPolicy, actualPolicy);
  }

  @IsTest
  static void getLegacyServiceTest() {
    Mock serviceMock = Mock.forType(IQuoteToOrderService.class);
    IQuoteToOrderService expectedService = (IQuoteToOrderService) serviceMock.stub;
    QuoteTriggerDependencies.legacyServiceOverride = expectedService;

    IQuoteToOrderService actualService = QuoteTriggerDependencies.getLegacyService();

    Assert.areEqual(expectedService, actualService);
  }

  @IsTest
  static void getNewServiceTest() {
    Mock serviceMock = Mock.forType(IQuoteToOrderService.class);
    IQuoteToOrderService expectedService = (IQuoteToOrderService) serviceMock.stub;
    QuoteTriggerDependencies.newServiceOverride = expectedService;

    IQuoteToOrderService actualService = QuoteTriggerDependencies.getNewService();

    Assert.areEqual(expectedService, actualService);
  }
}
