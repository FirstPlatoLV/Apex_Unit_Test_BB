/**
 * Persistence boundary required by QuoteToOrderService.
 * The service owns business decisions and object mapping; this contract owns
 * reads and the persistence workflow.
 */
public interface IQuoteToOrderDAO {
  Map<Id, Quote> findQuotes(Set<Id> quoteIds);
  List<QuoteLineItem> findQuoteLines(Set<Id> quoteIds);
  Map<Id, Id> saveOrders(
    Map<Id, Order> ordersByQuoteId,
    Map<Id, List<OrderItem>> itemsByQuoteId
  );
  void markQuotesConverted(Map<Id, Id> orderIdsByQuoteId);
}
