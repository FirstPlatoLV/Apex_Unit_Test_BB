public class QuoteToOrderResult {
  public Id orderId { get; private set; }
  public Integer orderItemCount { get; private set; }

  public QuoteToOrderResult(Id orderId, Integer orderItemCount) {
    this.orderId = orderId;
    this.orderItemCount = orderItemCount;
  }
}
