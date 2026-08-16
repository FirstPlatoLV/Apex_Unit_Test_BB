@IsTest
private class BrownbagDemoPolicyTest {
    @IsTest static void acceptedQuoteStatusTest() {
        System.assertEquals('Accepted',BrownbagDemoPolicy.acceptedQuoteStatus());
    }
}
