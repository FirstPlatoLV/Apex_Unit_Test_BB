public inherited sharing class QuoteToOrderService implements IQuoteToOrderService {
  private final IQuoteToOrderDAO dao;
  private final IDateProvider dateProvider;
  private final IQuoteConversionPolicy policy;

  public QuoteToOrderService(
    IQuoteToOrderDAO dao,
    IDateProvider dateProvider,
    IQuoteConversionPolicy policy
  ) {
    this.dao = dao;
    this.dateProvider = dateProvider;
    this.policy = policy;
  }

  public Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds) {
    if (quoteIds == null || quoteIds.isEmpty()) {
      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, Quote> quotesById = dao.findQuotes(quoteIds);
    if (quotesById.size() != quoteIds.size()) {
      throw new QuoteToOrderException('Quote does not exist');
    }
    String acceptedQuoteStatus = policy.acceptedQuoteStatus();
    Set<Id> eligibleQuoteIds = new Set<Id>();
    for (Id quoteId : quoteIds) {
      if (quotesById.get(quoteId).Status == acceptedQuoteStatus) {
        eligibleQuoteIds.add(quoteId);
      }
    }
    if (eligibleQuoteIds.isEmpty()) {
      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, List<QuoteLineItem>> linesByQuoteId = new Map<Id, List<QuoteLineItem>>();
    for (QuoteLineItem line : dao.findQuoteLines(eligibleQuoteIds)) {
      if (!linesByQuoteId.containsKey(line.QuoteId)) {
        linesByQuoteId.put(line.QuoteId, new List<QuoteLineItem>());
      }
      linesByQuoteId.get(line.QuoteId).add(line);
    }
    Date effectiveDate = dateProvider.today();
    Map<Id, Order> ordersByQuoteId = new Map<Id, Order>();
    Map<Id, List<OrderItem>> itemsByQuoteId = new Map<Id, List<OrderItem>>();
    for (Id quoteId : eligibleQuoteIds) {
      Quote quoteRecord = quotesById.get(quoteId);
      List<QuoteLineItem> lines = linesByQuoteId.get(quoteId);
      validate(quoteRecord, lines);
      ordersByQuoteId.put(
        quoteId,
        new Order(
          AccountId = quoteRecord.AccountId,
          EffectiveDate = effectiveDate,
          Pricebook2Id = quoteRecord.Pricebook2Id,
          Status = 'Draft'
        )
      );
      List<OrderItem> items = new List<OrderItem>();
      for (QuoteLineItem line : lines) {
        items.add(
          new OrderItem(
            PricebookEntryId = line.PricebookEntryId,
            Quantity = line.Quantity,
            UnitPrice = line.UnitPrice
          )
        );
      }
      itemsByQuoteId.put(quoteId, items);
    }
    Map<Id, Id> orderIdsByQuoteId = dao.saveOrders(
      ordersByQuoteId,
      itemsByQuoteId
    );
    dao.markQuotesConverted(orderIdsByQuoteId);
    Map<Id, QuoteToOrderResult> results = new Map<Id, QuoteToOrderResult>();
    for (Id quoteId : eligibleQuoteIds) {
      results.put(
        quoteId,
        new QuoteToOrderResult(
          orderIdsByQuoteId.get(quoteId),
          itemsByQuoteId.get(quoteId).size()
        )
      );
    }
    return results;
  }

  private void validate(Quote quoteRecord, List<QuoteLineItem> lines) {
    if (quoteRecord.Converted_Order__c != null) {
      throw new QuoteToOrderException('Quote was already converted');
    }
    if (quoteRecord.AccountId == null) {
      throw new QuoteToOrderException('Quote Account is required');
    }
    if (quoteRecord.Pricebook2Id == null) {
      throw new QuoteToOrderException('Quote Price Book is required');
    }
    if (lines == null || lines.isEmpty()) {
      throw new QuoteToOrderException('Quote must contain at least one line');
    }
  }
}
