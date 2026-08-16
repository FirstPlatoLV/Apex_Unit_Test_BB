public interface IOrderRepository {
    Id save(Order orderRecord, List<OrderItem> orderItems);
}
