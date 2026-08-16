@IsTest
private class QuoteToOrderExceptionTest {
  @IsTest
  static void constructorTest() {
    QuoteToOrderException error = new QuoteToOrderException(
      'Conversion failed'
    );

    Assert.areEqual('Conversion failed', error.getMessage());
  }
}
