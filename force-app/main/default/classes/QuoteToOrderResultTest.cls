@IsTest
private class QuoteToOrderResultTest {

  /** Verifies the result constructor exposes the Order ID and item count. */
  @IsTest
  static void constructorTest() {

    Id orderId = TestUtility.getFakeId(Order.SObjectType);
    QuoteToOrderResult result = new QuoteToOrderResult(orderId, 2);
    Assert.areEqual(orderId, result.orderId);
    Assert.areEqual(2, result.orderItemCount);
  }
}
