@IsTest
private class QuoteToOrderServiceFactoryTest {
    @IsTest static void createDefaultTest() {
        Assert.isNotNull(QuoteToOrderServiceFactory.createDefault());
    }
}
