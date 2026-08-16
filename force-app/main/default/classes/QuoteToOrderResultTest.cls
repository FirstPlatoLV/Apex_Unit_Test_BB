@IsTest
private class QuoteToOrderResultTest {
  @IsTest
  static void quoteToOrderResultTest() {
    Id orderId = TestUtility.getFakeId(Order.SObjectType);
    QuoteToOrderResult result = new QuoteToOrderResult(orderId, 2);
    Assert.areEqual(orderId, result.orderId);
    Assert.areEqual(2, result.orderItemCount);
  }
}
