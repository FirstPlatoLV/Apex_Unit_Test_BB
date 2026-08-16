public interface IQuoteRepository {
    Quote findById(Id quoteId);
    void markConverted(Id quoteId, Id orderId);
}
