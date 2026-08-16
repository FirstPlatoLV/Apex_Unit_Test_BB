public inherited sharing class SalesforceOrderRepository implements IOrderRepository {
    public Id save(Order orderRecord, List<OrderItem> orderItems) {
        insert orderRecord;
        for (OrderItem orderItem : orderItems) {
            orderItem.OrderId = orderRecord.Id;
        }
        insert orderItems;
        return orderRecord.Id;
    }
}
