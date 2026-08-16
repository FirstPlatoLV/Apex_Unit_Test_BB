@IsTest
private class QuoteToOrderResultTest {
    @IsTest static void quoteToOrderResultTest() {
        Id orderId='801000000000001AAA'; QuoteToOrderResult result=new QuoteToOrderResult(orderId,2);
        System.assertEquals(orderId,result.orderId); System.assertEquals(2,result.orderItemCount);
    }
}
