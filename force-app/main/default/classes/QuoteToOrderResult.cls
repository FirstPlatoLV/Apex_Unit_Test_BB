/**
 * Small return value shared by both implementations.
 * A common result contract lets callers compare or switch implementations
 * without inspecting persisted records immediately.
 */
public class QuoteToOrderResult {

  public Id orderId { get; private set; }
  public Integer orderItemCount { get; private set; }

  public QuoteToOrderResult(Id orderId, Integer orderItemCount) {

    this.orderId = orderId;
    this.orderItemCount = orderItemCount;
  }
}
