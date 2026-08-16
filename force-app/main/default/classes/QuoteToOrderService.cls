public inherited sharing class QuoteToOrderService {
  private final IQuoteToOrderDAO dao;
  private final IDateProvider dateProvider;
  private final IQuoteToOrderPolicy policy;

  public QuoteToOrderService(
    IQuoteToOrderDAO dao,
    IDateProvider dateProvider,
    IQuoteToOrderPolicy policy
  ) {
    this.dao = dao;
    this.dateProvider = dateProvider;
    this.policy = policy;
  }

  public QuoteToOrderResult convert(Id quoteId) {
    return convert(new Set<Id>{ quoteId }).get(quoteId);
  }

  public Map<Id, QuoteToOrderResult> convert(Set<Id> quoteIds) {
    if (quoteIds == null || quoteIds.isEmpty()) {
      return new Map<Id, QuoteToOrderResult>();
    }
    Map<Id, Quote> quotesById = dao.findQuotes(quoteIds);
    if (quotesById.size() != quoteIds.size()) {
      throw new QuoteToOrderException('Quote does not exist');
    }
    Map<Id, List<QuoteLineItem>> linesByQuoteId = new Map<Id, List<QuoteLineItem>>();
    for (QuoteLineItem line : dao.findQuoteLines(quoteIds)) {
      if (!linesByQuoteId.containsKey(line.QuoteId)) {
        linesByQuoteId.put(line.QuoteId, new List<QuoteLineItem>());
      }
      linesByQuoteId.get(line.QuoteId).add(line);
    }
    Date effectiveDate = dateProvider.today();
    String acceptedQuoteStatus = policy.acceptedQuoteStatus();
    Map<Id, Order> ordersByQuoteId = new Map<Id, Order>();
    Map<Id, List<OrderItem>> itemsByQuoteId = new Map<Id, List<OrderItem>>();
    for (Id quoteId : quoteIds) {
      Quote quoteRecord = quotesById.get(quoteId);
      List<QuoteLineItem> lines = linesByQuoteId.get(quoteId);
      validate(quoteRecord, lines, acceptedQuoteStatus);
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
    for (Id quoteId : quoteIds) {
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

  private void validate(
    Quote quoteRecord,
    List<QuoteLineItem> lines,
    String acceptedQuoteStatus
  ) {
    if (quoteRecord.Status != acceptedQuoteStatus) {
      throw new QuoteToOrderException('Quote status is not accepted');
    }
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
