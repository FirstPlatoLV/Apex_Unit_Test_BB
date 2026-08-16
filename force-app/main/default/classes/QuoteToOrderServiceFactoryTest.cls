@IsTest
private class QuoteToOrderServiceFactoryTest {
    @IsTest static void createDefaultTest() {
        System.assertNotEquals(null,QuoteToOrderServiceFactory.createDefault());
    }
}
