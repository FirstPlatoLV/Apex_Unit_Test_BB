/**
 * Shared boundary used by trigger orchestration.
 *
 * Both the transitional legacy class and the dependency-injected service
 * implement this contract. The trigger can therefore switch implementations
 * without knowing how either service obtains data or performs DML.
 */
public interface IQuoteToOrderService {
  Map<Id, QuoteToOrderResult> convertQuotes(Set<Id> quoteIds);
}
