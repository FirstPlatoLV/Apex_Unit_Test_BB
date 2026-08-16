public interface IQuoteLineRepository {
    List<QuoteLineItem> findByQuoteId(Id quoteId);
}
