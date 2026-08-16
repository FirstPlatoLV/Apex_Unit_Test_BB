@IsTest
private class BrownbagDemoPolicyTest {
    @IsTest static void acceptedQuoteStatusTest() {
        Assert.areEqual('Accepted',BrownbagDemoPolicy.acceptedQuoteStatus());
    }
}
