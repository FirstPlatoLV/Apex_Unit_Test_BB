@IsTest
private class SystemDateProviderTest {
    @IsTest static void todayTest() {
        System.assertEquals(Date.today(),new SystemDateProvider().today());
    }
}
