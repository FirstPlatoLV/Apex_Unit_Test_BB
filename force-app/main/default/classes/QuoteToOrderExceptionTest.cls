@IsTest
private class QuoteToOrderExceptionTest {
  /** Verifies the custom exception constructor preserves its message. */
  @IsTest
  static void constructorTest() {
    QuoteToOrderException error = new QuoteToOrderException(
      'Conversion failed'
    );

    Assert.areEqual('Conversion failed', error.getMessage());
  }
}
