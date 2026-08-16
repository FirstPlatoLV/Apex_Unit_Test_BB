public interface IQuoteToOrderService {
  Map<Id, QuoteToOrderResult> convertQuotes(Set<Id> quoteIds);
}
