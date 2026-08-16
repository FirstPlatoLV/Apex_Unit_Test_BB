public interface IQuoteToOrderService {
  Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds);
}
